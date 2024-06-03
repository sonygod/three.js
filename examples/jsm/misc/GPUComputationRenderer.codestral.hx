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

    private var variables:Array<Dynamic>;
    private var currentTextureIndex:Int;
    private var dataType:Int;
    private var scene:Scene;
    private var camera:Camera;
    private var passThruUniforms:Dynamic;
    private var passThruShader:ShaderMaterial;
    private var mesh:Mesh;

    public function new(sizeX:Int, sizeY:Int, renderer:WebGLRenderer) {
        this.variables = new Array<Dynamic>();
        this.currentTextureIndex = 0;
        this.dataType = FloatType;
        this.scene = new Scene();
        this.camera = new Camera();
        this.camera.position.z = 1;
        this.passThruUniforms = {
            passThruTexture: { value: null }
        };
        this.passThruShader = this.createShaderMaterial(this.getPassThroughFragmentShader(), this.passThruUniforms);
        this.mesh = new Mesh(new PlaneGeometry(2, 2), this.passThruShader);
        this.scene.add(this.mesh);
    }

    public function setDataType(type:Int):GPUComputationRenderer {
        this.dataType = type;
        return this;
    }

    public function addVariable(variableName:String, computeFragmentShader:String, initialValueTexture:DataTexture):Dynamic {
        var material:ShaderMaterial = this.createShaderMaterial(computeFragmentShader);
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
    }

    public function setVariableDependencies(variable:Dynamic, dependencies:Array<Dynamic>):Void {
        variable.dependencies = dependencies;
    }

    public function init():String {
        if (renderer.capabilities.maxVertexTextures == 0) {
            return 'No support for vertex shader textures.';
        }

        for (i in 0...this.variables.length) {
            var variable:Dynamic = this.variables[i];
            variable.renderTargets[0] = this.createRenderTarget(sizeX, sizeY, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter);
            variable.renderTargets[1] = this.createRenderTarget(sizeX, sizeY, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter);
            this.renderTexture(variable.initialValueTexture, variable.renderTargets[0]);
            this.renderTexture(variable.initialValueTexture, variable.renderTargets[1]);

            var material:ShaderMaterial = variable.material;
            var uniforms:Dynamic = material.uniforms;

            if (variable.dependencies != null) {
                for (d in 0...variable.dependencies.length) {
                    var depVar:Dynamic = variable.dependencies[d];

                    if (depVar.name != variable.name) {
                        var found:Bool = false;

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
    }

    public function compute():Void {
        var currentTextureIndex:Int = this.currentTextureIndex;
        var nextTextureIndex:Int = this.currentTextureIndex == 0 ? 1 : 0;

        for (i in 0...this.variables.length) {
            var variable:Dynamic = this.variables[i];

            if (variable.dependencies != null) {
                var uniforms:Dynamic = variable.material.uniforms;

                for (d in 0...variable.dependencies.length) {
                    var depVar:Dynamic = variable.dependencies[d];
                    uniforms[depVar.name].value = depVar.renderTargets[currentTextureIndex].texture;
                }
            }

            this.doRenderTarget(variable.material, variable.renderTargets[nextTextureIndex]);
        }

        this.currentTextureIndex = nextTextureIndex;
    }

    public function getCurrentRenderTarget(variable:Dynamic):WebGLRenderTarget {
        return variable.renderTargets[this.currentTextureIndex];
    }

    public function getAlternateRenderTarget(variable:Dynamic):WebGLRenderTarget {
        return variable.renderTargets[this.currentTextureIndex == 0 ? 1 : 0];
    }

    public function dispose():Void {
        this.mesh.geometry.dispose();
        this.mesh.material.dispose();

        for (i in 0...this.variables.length) {
            var variable:Dynamic = this.variables[i];

            if (variable.initialValueTexture != null) variable.initialValueTexture.dispose();

            for (j in 0...variable.renderTargets.length) {
                var renderTarget:WebGLRenderTarget = variable.renderTargets[j];
                renderTarget.dispose();
            }
        }
    }

    public function addResolutionDefine(materialShader:ShaderMaterial):Void {
        materialShader.defines.resolution = 'vec2(' + sizeX.toFixed(1) + ', ' + sizeY.toFixed(1) + ')';
    }

    private function createShaderMaterial(computeFragmentShader:String, uniforms:Dynamic = null):ShaderMaterial {
        if (uniforms == null) uniforms = {};

        var material:ShaderMaterial = new ShaderMaterial({
            name: 'GPUComputationShader',
            uniforms: uniforms,
            vertexShader: this.getPassThroughVertexShader(),
            fragmentShader: computeFragmentShader
        });

        this.addResolutionDefine(material);
        return material;
    }

    public function createRenderTarget(sizeXTexture:Int = null, sizeYTexture:Int = null, wrapS:Int = null, wrapT:Int = null, minFilter:Int = null, magFilter:Int = null):WebGLRenderTarget {
        sizeXTexture = sizeXTexture != null ? sizeXTexture : sizeX;
        sizeYTexture = sizeYTexture != null ? sizeYTexture : sizeY;

        wrapS = wrapS != null ? wrapS : ClampToEdgeWrapping;
        wrapT = wrapT != null ? wrapT : ClampToEdgeWrapping;

        minFilter = minFilter != null ? minFilter : NearestFilter;
        magFilter = magFilter != null ? magFilter : NearestFilter;

        var renderTarget:WebGLRenderTarget = new WebGLRenderTarget(sizeXTexture, sizeYTexture, {
            wrapS: wrapS,
            wrapT: wrapT,
            minFilter: minFilter,
            magFilter: magFilter,
            format: RGBAFormat,
            type: this.dataType,
            depthBuffer: false
        });

        return renderTarget;
    }

    public function createTexture():DataTexture {
        var data:Float = new Float32Array(sizeX * sizeY * 4);
        var texture:DataTexture = new DataTexture(data, sizeX, sizeY, RGBAFormat, FloatType);
        texture.needsUpdate = true;
        return texture;
    }

    public function renderTexture(input:DataTexture, output:WebGLRenderTarget):Void {
        this.passThruUniforms.passThruTexture.value = input;
        this.doRenderTarget(this.passThruShader, output);
        this.passThruUniforms.passThruTexture.value = null;
    }

    public function doRenderTarget(material:ShaderMaterial, output:WebGLRenderTarget):Void {
        var currentRenderTarget:WebGLRenderTarget = renderer.getRenderTarget();

        var currentXrEnabled:Bool = renderer.xr.enabled;
        var currentShadowAutoUpdate:Bool = renderer.shadowMap.autoUpdate;

        renderer.xr.enabled = false;
        renderer.shadowMap.autoUpdate = false;
        this.mesh.material = material;
        renderer.setRenderTarget(output);
        renderer.render(this.scene, this.camera);
        this.mesh.material = this.passThruShader;

        renderer.xr.enabled = currentXrEnabled;
        renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;

        renderer.setRenderTarget(currentRenderTarget);
    }

    private function getPassThroughVertexShader():String {
        return 'void main() {\n' +
               '\n' +
               '    gl_Position = vec4(position, 1.0);\n' +
               '\n' +
               '}\n';
    }

    private function getPassThroughFragmentShader():String {
        return 'uniform sampler2D passThruTexture;\n' +
               '\n' +
               'void main() {\n' +
               '\n' +
               '    vec2 uv = gl_FragCoord.xy / resolution.xy;\n' +
               '\n' +
               '    gl_FragColor = texture2D(passThruTexture, uv);\n' +
               '\n' +
               '}\n';
    }
}