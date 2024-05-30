package three.js.misc;

import three.js.renderers.WebGLRenderTarget;
import three.js.textures.DataTexture;
import three.js.textures.Texture;
import three.js.core.Material;
import three.js.core.Mesh;
import three.js.core.Object3D;
import three.js.core.Renderer;
import three.js.core.Scene;
import three.js.core.Camera;
import three.js.geometries.PlaneGeometry;
import three.js.materials.ShaderMaterial;

class GPUComputationRenderer {
    public var variables:Array<Variable>;
    public var currentTextureIndex:Int;
    public var dataType:Int;

    public function new(sizeX:Int, sizeY:Int, renderer:Renderer) {
        variables = new Array<Variable>();
        currentTextureIndex = 0;
        dataType = FloatType;

        var scene = new Scene();
        var camera = new Camera();
        camera.position.z = 1;

        var passThruUniforms = {
            passThruTexture: { value: null }
        };

        var passThruShader = createShaderMaterial(getPassThroughFragmentShader(), passThruUniforms);

        var mesh = new Mesh(new PlaneGeometry(2, 2), passThruShader);
        scene.add(mesh);

        this.setDataType = function(type:Int) {
            dataType = type;
            return this;
        };

        this.addVariable = function(variableName:String, computeFragmentShader:String, initialValueTexture:Texture) {
            var material = createShaderMaterial(computeFragmentShader);

            var variable = {
                name: variableName,
                initialValueTexture: initialValueTexture,
                material: material,
                dependencies: null,
                renderTargets: [],
                wrapS: null,
                wrapT: null,
                minFilter: NearestFilter,
                magFilter: NearestFilter
            };

            variables.push(variable);

            return variable;
        };

        this.setVariableDependencies = function(variable:Variable, dependencies:Array<Variable>) {
            variable.dependencies = dependencies;
        };

        this.init = function() {
            if (renderer.capabilities.maxVertexTextures === 0) {
                return 'No support for vertex shader textures.';
            }

            for (i in 0...variables.length) {
                var variable = variables[i];

                variable.renderTargets[0] = createRenderTarget(sizeX, sizeY, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter);
                variable.renderTargets[1] = createRenderTarget(sizeX, sizeY, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter);
                renderTexture(variable.initialValueTexture, variable.renderTargets[0]);
                renderTexture(variable.initialValueTexture, variable.renderTargets[1]);

                var material = variable.material;
                var uniforms = material.uniforms;

                if (variable.dependencies != null) {
                    for (dep in variable.dependencies) {
                        uniforms[dep.name] = { value: null };
                        material.fragmentShader += '\nuniform sampler2D ' + dep.name + ';\n';
                    }
                }
            }

            currentTextureIndex = 0;

            return null;
        };

        this.compute = function() {
            var currentTextureIndex = this.currentTextureIndex;
            var nextTextureIndex = this.currentTextureIndex === 0 ? 1 : 0;

            for (i in 0...variables.length) {
                var variable = variables[i];

                if (variable.dependencies != null) {
                    for (dep in variable.dependencies) {
                        variable.material.uniforms[dep.name].value = dep.renderTargets[currentTextureIndex].texture;
                    }
                }

                doRenderTarget(variable.material, variable.renderTargets[nextTextureIndex]);
            }

            this.currentTextureIndex = nextTextureIndex;
        };

        this.getCurrentRenderTarget = function(variable:Variable) {
            return variable.renderTargets[currentTextureIndex];
        };

        this.getAlternateRenderTarget = function(variable:Variable) {
            return variable.renderTargets[currentTextureIndex === 0 ? 1 : 0];
        };

        this.dispose = function() {
            mesh.geometry.dispose();
            mesh.material.dispose();

            for (i in variables) {
                var variable = i;

                if (variable.initialValueTexture != null) {
                    variable.initialValueTexture.dispose();
                }

                for (j in variable.renderTargets) {
                    j.dispose();
                }
            }
        };

        function addResolutionDefine(material:Material) {
            material.defines.resolution = 'vec2(' + sizeX + ', ' + sizeY + ')';
        }

        this.addResolutionDefine = addResolutionDefine;

        this.createShaderMaterial = function(computeFragmentShader:String, uniforms:Dynamic) {
            uniforms = uniforms || {};

            var material = new ShaderMaterial({
                vertexShader: getPassThroughVertexShader(),
                fragmentShader: computeFragmentShader,
                uniforms: uniforms
            });

            addResolutionDefine(material);

            return material;
        };

        this.createRenderTarget = function(sizeXTexture:Int, sizeYTexture:Int, wrapS:Null<Int>, wrapT:Null<Int>, minFilter:Int, magFilter:Int) {
            sizeXTexture = sizeXTexture != null ? sizeXTexture : sizeX;
            sizeYTexture = sizeYTexture != null ? sizeYTexture : sizeY;

            wrapS = wrapS != null ? wrapS : ClampToEdgeWrapping;
            wrapT = wrapT != null ? wrapT : ClampToEdgeWrapping;

            minFilter = minFilter != null ? minFilter : NearestFilter;
            magFilter = magFilter != null ? magFilter : NearestFilter;

            var renderTarget = new WebGLRenderTarget(sizeXTexture, sizeYTexture, {
                wrapS: wrapS,
                wrapT: wrapT,
                minFilter: minFilter,
                magFilter: magFilter,
                format: RGBAFormat,
                type: dataType,
                depthBuffer: false
            });

            return renderTarget;
        };

        this.createTexture = function() {
            var data = new Float32Array(sizeX * sizeY * 4);
            var texture = new DataTexture(data, sizeX, sizeY, RGBAFormat, FloatType);
            texture.needsUpdate = true;
            return texture;
        };

        this.renderTexture = function(input:Texture, output:WebGLRenderTarget) {
            passThruUniforms.passThruTexture.value = input;

            doRenderTarget(passThruShader, output);

            passThruUniforms.passThruTexture.value = null;
        };

        this.doRenderTarget = function(material:Material, output:WebGLRenderTarget) {
            var currentRenderTarget = renderer.getRenderTarget();

            var currentXrEnabled = renderer.xr.enabled;
            var currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

            renderer.xr.enabled = false;
            renderer.shadowMap.autoUpdate = false;

            mesh.material = material;
            renderer.setRenderTarget(output);
            renderer.render(scene, camera);

            mesh.material = passThruShader;

            renderer.xr.enabled = currentXrEnabled;
            renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;

            renderer.setRenderTarget(currentRenderTarget);
        };

        function getPassThroughVertexShader() {
            return '
                void main() {
                    gl_Position = vec4( position, 1.0 );
                }
            ';
        }

        function getPassThroughFragmentShader() {
            return '
                uniform sampler2D passThruTexture;
                void main() {
                    vec2 uv = gl_FragCoord.xy / resolution.xy;
                    gl_FragColor = texture2D( passThruTexture, uv );
                }
            ';
        }
    }
}