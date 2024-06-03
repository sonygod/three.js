import js.Browser.document;
import js.html.WebGLRenderingContext;
import js.webgl.WebGLShader;
import js.webgl.WebGLUniformLocation;
import threejs.constants.*;
import threejs.math.ColorManagement;
import threejs.shaders.ShaderChunk;

class WebGLProgram {
    public var program: WebGLProgram;
    public var cacheKey: String;
    public var type: Int;
    public var name: String;
    public var id: Int;
    public var usedTimes: Int;

    private var gl: WebGLRenderingContext;
    private var programReady: Bool;
    private var cachedUniforms: WebGLUniforms;
    private var cachedAttributes: Dynamic;

    public function new(renderer: WebGLRenderer, cacheKey: String, parameters: Dynamic, bindingStates: Dynamic) {
        this.gl = renderer.getContext();

        var defines = parameters.defines;
        var vertexShader = parameters.vertexShader;
        var fragmentShader = parameters.fragmentShader;

        var shadowMapTypeDefine = generateShadowMapTypeDefine(parameters);
        var envMapTypeDefine = generateEnvMapTypeDefine(parameters);
        var envMapModeDefine = generateEnvMapModeDefine(parameters);
        var envMapBlendingDefine = generateEnvMapBlendingDefine(parameters);
        var envMapCubeUVSize = generateCubeUVSize(parameters);

        var customVertexExtensions = generateVertexExtensions(parameters);
        var customDefines = generateDefines(defines);

        this.program = this.gl.createProgram();

        var prefixVertex: String;
        var prefixFragment: String;
        var versionString = parameters.glslVersion ? '#version ' + parameters.glslVersion + '\n' : '';

        if (parameters.isRawShaderMaterial) {
            // ... rest of the raw shader material logic
        } else {
            // ... rest of the built-in materials and ShaderMaterial logic
        }

        vertexShader = resolveIncludes(vertexShader);
        vertexShader = replaceLightNums(vertexShader, parameters);
        vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

        fragmentShader = resolveIncludes(fragmentShader);
        fragmentShader = replaceLightNums(fragmentShader, parameters);
        fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

        vertexShader = unrollLoops(vertexShader);
        fragmentShader = unrollLoops(fragmentShader);

        // ... rest of the shader compilation and linking logic

        this.cacheKey = cacheKey;
        this.type = parameters.shaderType;
        this.name = parameters.shaderName;
        this.id = programIdCount++;
        this.usedTimes = 1;

        return this;
    }

    public function getUniforms(): WebGLUniforms {
        if (this.cachedUniforms == null) {
            onFirstUse(this);
        }
        return this.cachedUniforms;
    }

    public function getAttributes(): Dynamic {
        if (this.cachedAttributes == null) {
            onFirstUse(this);
        }
        return this.cachedAttributes;
    }

    public function isReady(): Bool {
        if (!this.programReady) {
            this.programReady = this.gl.getProgramParameter(this.program, COMPLETION_STATUS_KHR);
        }
        return this.programReady;
    }

    public function destroy(): Void {
        bindingStates.releaseStatesOfProgram(this);
        this.gl.deleteProgram(this.program);
        this.program = null;
    }
}

// ... rest of the functions