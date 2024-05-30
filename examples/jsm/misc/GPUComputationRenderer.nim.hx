import three.js.examples.jsm.misc.GPUComputationRenderer;
import three.js.Camera;
import three.js.ClampToEdgeWrapping;
import three.js.DataTexture;
import three.js.FloatType;
import three.js.Mesh;
import three.js.NearestFilter;
import three.js.PlaneGeometry;
import three.js.RGBAFormat;
import three.js.Scene;
import three.js.ShaderMaterial;
import three.js.WebGLRenderTarget;

class Main {
    static function main() {
        var gpuCompute = new GPUComputationRenderer(1024, 1024, new three.js.WebGLRenderer());

        var pos0 = gpuCompute.createTexture();
        var vel0 = gpuCompute.createTexture();

        var velVar = gpuCompute.addVariable("textureVelocity", fragmentShaderVel, pos0);
        var posVar = gpuCompute.addVariable("texturePosition", fragmentShaderPos, vel0);

        gpuCompute.setVariableDependencies(velVar, [velVar, posVar]);
        gpuCompute.setVariableDependencies(posVar, [velVar, posVar]);

        velVar.material.uniforms.time = { value: 0.0 };

        var error = gpuCompute.init();
        if (error != null) {
            trace(error);
        }

        gpuCompute.compute();

        // Do your rendering
        // renderer.render(myScene, myCamera);
    }
}

class GPUComputationRenderer {
    public var variables:Array<Dynamic>;
    public var currentTextureIndex:Int;

    public function new(sizeX:Int, sizeY:Int, renderer:three.js.WebGLRenderer) {
        this.variables = [];
        this.currentTextureIndex = 0;

        var dataType = FloatType;

        var scene = new Scene();
        var camera = new Camera();
        camera.position.z = 1;

        var passThruUniforms = {
            passThruTexture: { value: null }
        };

        var passThruShader = createShaderMaterial(getPassThroughFragmentShader(), passThruUniforms);

        var mesh = new Mesh(new PlaneGeometry(2, 2), passThruShader);
        scene.add(mesh);

        this.setDataType = function(type:Dynamic) {
            dataType = type;
            return this;
        };

        this.addVariable = function(variableName:String, computeFragmentShader:String, initialValueTexture:Dynamic) {
            var material = this.createShaderMaterial(computeFragmentShader);

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

            this.variables.push(variable);

            return variable;
        };

        this.setVariableDependencies = function(variable:Dynamic, dependencies:Array<Dynamic>) {
            variable.dependencies = dependencies;
        };

        this.init = function() {
            if (renderer.capabilities.maxVertexTextures == 0) {
                return 'No support for vertex shader textures.';
            }

            for (i in 0...this.variables.length) {
                var variable = this.variables[i];

                // Creates rendertargets and initialize them with input texture
                variable.renderTargets[0] = this.createRenderTarget(sizeX, sizeY, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter);
                variable.renderTargets[1] = this.createRenderTarget(sizeX, sizeY, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter);
                this.renderTexture(variable.initialValueTexture, variable.renderTargets[0]);
                this.renderTexture(variable.initialValueTexture, variable.renderTargets[1]);

                // Adds dependencies uniforms to the ShaderMaterial
                var material = variable.material;
                var uniforms = material.uniforms;

                if (variable.dependencies != null) {
                    for (d in 0...variable.dependencies.length) {
                        var depVar = variable.dependencies[d];

                        if (depVar.name != variable.name) {
                            // Checks if variable exists
                            var found = false;

                            for (j in 0...this.variables.length) {
                                if (depVar.name == this.variables[j].name) {
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

            this.currentTextureIndex = 0;

            return null;
        };

        this.compute = function() {
            var currentTextureIndex = this.currentTextureIndex;
            var nextTextureIndex = this.currentTextureIndex == 0 ? 1 : 0;

            for (i in 0...this.variables.length) {
                var variable = this.variables[i];

                // Sets texture dependencies uniforms
                if (variable.dependencies != null) {
                    var uniforms = variable.material.uniforms;

                    for (d in 0...variable.dependencies.length) {
                        var depVar = variable.dependencies[d];

                        uniforms[depVar.name].value = depVar.renderTargets[currentTextureIndex].texture;
                    }
                }

                // Performs the computation for this variable
                this.doRenderTarget(variable.material, variable.renderTargets[nextTextureIndex]);
            }

            this.currentTextureIndex = nextTextureIndex;
        };

        this.getCurrentRenderTarget = function(variable:Dynamic) {
            return variable.renderTargets[this.currentTextureIndex];
        };

        this.getAlternateRenderTarget = function(variable:Dynamic) {
            return variable.renderTargets[this.currentTextureIndex == 0 ? 1 : 0];
        };

        this.dispose = function() {
            mesh.geometry.dispose();
            mesh.material.dispose();

            var variables = this.variables;

            for (i in 0...variables.length) {
                var variable = variables[i];

                if (variable.initialValueTexture) variable.initialValueTexture.dispose();

                var renderTargets = variable.renderTargets;

                for (j in 0...renderTargets.length) {
                    var renderTarget = renderTargets[j];
                    renderTarget.dispose();
                }
            }
        };

        function addResolutionDefine(materialShader:Dynamic) {
            materialShader.defines.resolution = 'vec2( ' + sizeX.toString() + ', ' + sizeY.toString() + ' )';
        }

        this.addResolutionDefine = addResolutionDefine;

        // The following functions can be used to compute things manually

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

        this.createRenderTarget = function(sizeXTexture:Int, sizeYTexture:Int, wrapS:Dynamic, wrapT:Dynamic, minFilter:Dynamic, magFilter:Dynamic) {
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

        this.createTexture = function() {
            var data = new Float32Array(sizeX * sizeY * 4);
            var texture = new DataTexture(data, sizeX, sizeY, RGBAFormat, FloatType);
            texture.needsUpdate = true;
            return texture;
        };

        this.renderTexture = function(input:Dynamic, output:Dynamic) {
            // Takes a texture, and render out in rendertarget
            // input = Texture
            // output = RenderTarget

            passThruUniforms.passThruTexture.value = input;

            this.doRenderTarget(passThruShader, output);

            passThruUniforms.passThruTexture.value = null;
        };

        this.doRenderTarget = function(material:Dynamic, output:Dynamic) {
            var currentRenderTarget = renderer.getRenderTarget();

            var currentXrEnabled = renderer.xr.enabled;
            var currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

            renderer.xr.enabled = false; // Avoid camera modification
            renderer.shadowMap.autoUpdate = false; // Avoid re-computing shadows
            mesh.material = material;
            renderer.setRenderTarget(output);
            renderer.render(scene, camera);
            mesh.material = passThruShader;

            renderer.xr.enabled = currentXrEnabled;
            renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;

            renderer.setRenderTarget(currentRenderTarget);
        };

        // Shaders

        function getPassThroughVertexShader() {
            return 'void main() {\n' +
                '\n' +
                'gl_Position = vec4(position, 1.0);\n' +
                '\n' +
                '}';
        }

        function getPassThroughFragmentShader() {
            return 'uniform sampler2D passThruTexture;\n' +
                '\n' +
                'void main() {\n' +
                '\n' +
                'vec2 uv = gl_FragCoord.xy / resolution.xy;\n' +
                '\n' +
                'gl_FragColor = texture2D(passThruTexture, uv);\n' +
                '\n' +
                '}';
        }
    }
}