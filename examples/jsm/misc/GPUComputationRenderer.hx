package three.js.examples.jsm.misc;

import three.Camera;
import three.ClampToEdgeWrapping;
import three.DataTexture;
import three.FloatType;
import three.Mesh;
import three.NearestFilter;
import three.PlaneGeometry;
import three.RGBAFormat;
import three.Scene;
import three.ShaderMaterial;
import three.WebGLRenderTarget;

class GPUComputationRenderer {
    public var variables:Array<Dynamic>;
    public var currentTextureIndex:Int;
    public var dataType:FloatType;

    public function new(sizeX:Int, sizeY:Int, renderer:WebGLRenderer) {
        variables = [];
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

        this.setDataType = function (type:FloatType) {
            dataType = type;
            return this;
        };

        this.addVariable = function (variableName:String, computeFragmentShader:String, initialValueTexture:DataTexture) {
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

        this.setVariableDependencies = function (variable:Dynamic, dependencies:Array<Dynamic>) {
            variable.dependencies = dependencies;
        };

        this.init = function () {
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

                if (variable.dependencies !== null) {
                    for (d in 0...variable.dependencies.length) {
                        var depVar = variable.dependencies[d];

                        if (depVar.name !== variable.name) {
                            var found = false;

                            for (j in 0...variables.length) {
                                if (depVar.name === variables[j].name) {
                                    found = true;
                                    break;
                                }
                            }

                            if (!found) {
                                return 'Variable dependency not found. Variable=' + variable.name + ', dependency=' + depVar.name;
                            }
                        }

                        uniforms[depVar.name] = { value: null };

                        material.fragmentShader = '\nuniform sampler2D ' + depVar.name + ';\n' + material.fragmentShader;
                    }
                }
            }

            currentTextureIndex = 0;

            return null;
        };

        this.compute = function () {
            var currentTextureIndex = this.currentTextureIndex;
            var nextTextureIndex = this.currentTextureIndex === 0 ? 1 : 0;

            for (i in 0...variables.length) {
                var variable = variables[i];

                if (variable.dependencies !== null) {
                    var uniforms = variable.material.uniforms;

                    for (d in 0...variable.dependencies.length) {
                        var depVar = variable.dependencies[d];

                        uniforms[depVar.name].value = depVar.renderTargets[currentTextureIndex].texture;
                    }
                }

                doRenderTarget(variable.material, variable.renderTargets[nextTextureIndex]);
            }

            currentTextureIndex = nextTextureIndex;
        };

        this.getCurrentRenderTarget = function (variable:Dynamic) {
            return variable.renderTargets[currentTextureIndex];
        };

        this.getAlternateRenderTarget = function (variable:Dynamic) {
            return variable.renderTargets[currentTextureIndex === 0 ? 1 : 0];
        };

        this.dispose = function () {
            mesh.geometry.dispose();
            mesh.material.dispose();

            for (i in 0...variables.length) {
                var variable = variables[i];

                if (variable.initialValueTexture) variable.initialValueTexture.dispose();

                for (j in 0...variable.renderTargets.length) {
                    variable.renderTargets[j].dispose();
                }
            }
        };

        function addResolutionDefine(materialShader:ShaderMaterial) {
            materialShader.defines.resolution = 'vec2( ${sizeX.toFixed(1)}, ${sizeY.toFixed(1)} )';
        }

        this.addResolutionDefine = addResolutionDefine;

        function createShaderMaterial(computeFragmentShader:String, uniforms:Dynamic) {
            uniforms = uniforms || {};

            var material = new ShaderMaterial({
                name: 'GPUComputationShader',
                uniforms: uniforms,
                vertexShader: getPassThroughVertexShader(),
                fragmentShader: computeFragmentShader
            });

            addResolutionDefine(material);

            return material;
        }

        this.createShaderMaterial = createShaderMaterial;

        this.createRenderTarget = function (sizeXTexture:Int, sizeYTexture:Int, wrapS:ClampToEdgeWrapping, wrapT:ClampToEdgeWrapping, minFilter:NearestFilter, magFilter:NearestFilter) {
            sizeXTexture = sizeXTexture || sizeX;
            sizeYTexture = sizeYTexture || sizeY;

            wrapS = wrapS || ClampToEdgeWrapping;
            wrapT = wrapT || ClampToEdgeWrapping;

            minFilter = minFilter || NearestFilter;
            magFilter = magFilter || NearestFilter;

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

        this.createTexture = function ():DataTexture {
            var data = new Float32Array(sizeX * sizeY * 4);
            var texture = new DataTexture(data, sizeX, sizeY, RGBAFormat, FloatType);
            texture.needsUpdate = true;
            return texture;
        };

        this.renderTexture = function (input:DataTexture, output:WebGLRenderTarget) {
            passThruUniforms.passThruTexture.value = input;

            doRenderTarget(passThruShader, output);

            passThruUniforms.passThruTexture.value = null;
        };

        this.doRenderTarget = function (material:ShaderMaterial, output:WebGLRenderTarget) {
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
    }

    function getPassThroughVertexShader():String {
        return 'void main() {\n' +
               '	gl_Position = vec4( position, 1.0 );\n' +
               '}\n';
    }

    function getPassThroughFragmentShader():String {
        return 'uniform sampler2D passThruTexture;\n' +
               'void main() {\n' +
               '	vec2 uv = gl_FragCoord.xy / resolution.xy;\n' +
               '	gl_FragColor = texture2D( passThruTexture, uv );\n' +
               '}\n';
    }
}