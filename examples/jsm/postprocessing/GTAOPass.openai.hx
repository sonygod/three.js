package three.js.examples.jsm.postprocessing;

import three.Counter;
import three.DataTexture;
import three.DepthStencilFormat;
import three.DstAlphaFactor;
import three.DstColorFactor;
import three.HalfFloatType;
import three.MeshNormalMaterial;
import three.NearestFilter;
import three.NoBlending;
import three.RepeatWrapping;
import three.RGBAFormat;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.UnsignedByteType;
import three.UnsignedInt248Type;
import three.WebGLRenderTarget;
import three.ZeroFactor;

import Pass;
import FullScreenQuad;

import three.shaders.GTAOShader;
import three.shaders.GTAODepthShader;
import three.shaders.GTAOBlendShader;
import three.shaders.PoissonDenoiseShader;
import three.shaders.CopyShader;

import SimplexNoise;

class GTAOPass extends Pass {
    public var scene:Scene;
    public var camera:Camera;
    public var width:Int;
    public var height:Int;
    public var output:Int;
    public var clear:Bool;
    public var renderTarget:WebGLRenderTarget;
    public var normalRenderTarget:WebGLRenderTarget;
    public var pdRenderTarget:WebGLRenderTarget;
    public var gtaoMaterial:ShaderMaterial;
    public var pdMaterial:ShaderMaterial;
    public var copyMaterial:ShaderMaterial;
    public var blendMaterial:ShaderMaterial;
    public var fsQuad:FullScreenQuad;
    public var originalClearColor:Color;
    public var pdRings:Float;
    public var pdRadiusExponent:Float;
    public var pdSamples:Int;
    public var gtaoNoiseTexture:DataTexture;
    public var pdNoiseTexture:DataTexture;
    public var _renderGBuffer:Bool;
    public var _visibilityCache:Map<Object, Bool>;

    public function new(scene:Scene, camera:Camera, width:Int, height:Int, parameters:Dynamic, aoParameters:Dynamic, pdParameters:Dynamic) {
        super();
        this.scene = scene;
        this.camera = camera;
        this.width = width;
        this.height = height;
        this.clear = true;
        this.output = 0;
        this._renderGBuffer = true;
        this._visibilityCache = new Map();
        this.blendIntensity = 1.0;

        this.pdRings = 2.0;
        this.pdRadiusExponent = 2.0;
        this.pdSamples = 16;

        this.gtaoNoiseTexture = generateMagicSquareNoise();
        this.pdNoiseTexture = generateNoise();

        this.gtaoRenderTarget = new WebGLRenderTarget(width, height, { type: HalfFloatType });
        this.pdRenderTarget = this.gtaoRenderTarget.clone();

        this.gtaoMaterial = new ShaderMaterial({
            defines: GTAODefines,
            uniforms: UniformsUtils.clone(GTAOUniforms),
            vertexShader: GTAOShader.vertexShader,
            fragmentShader: GTAOShader.fragmentShader,
            blending: NoBlending,
            depthTest: false,
            depthWrite: false
        });
        this.gtaoMaterial.defines.PERSPECTIVE_CAMERA = camera.isPerspectiveCamera ? 1 : 0;
        this.gtaoMaterial.uniforms.tNoise.value = this.gtaoNoiseTexture;
        this.gtaoMaterial.uniforms.resolution.value.set(width, height);
        this.gtaoMaterial.uniforms.cameraNear.value = camera.near;
        this.gtaoMaterial.uniforms.cameraFar.value = camera.far;

        this.normalMaterial = new MeshNormalMaterial();
        this.normalMaterial.blending = NoBlending;

        this.pdMaterial = new ShaderMaterial({
            defines: PoissonDenoiseDefines,
            uniforms: UniformsUtils.clone(PoissonDenoiseUniforms),
            vertexShader: PoissonDenoiseShader.vertexShader,
            fragmentShader: PoissonDenoiseShader.fragmentShader,
            depthTest: false,
            depthWrite: false
        });
        this.pdMaterial.uniforms.tDiffuse.value = this.gtaoRenderTarget.texture;
        this.pdMaterial.uniforms.tNoise.value = this.pdNoiseTexture;
        this.pdMaterial.uniforms.resolution.value.set(width, height);
        this.pdMaterial.uniforms.lumaPhi.value = 10;
        this.pdMaterial.uniforms.depthPhi.value = 2;
        this.pdMaterial.uniforms.normalPhi.value = 3;
        this.pdMaterial.uniforms.radius.value = 8;

        this.depthRenderMaterial = new ShaderMaterial({
            defines: GTAODepthDefines,
            uniforms: UniformsUtils.clone(GTAODepthUniforms),
            vertexShader: GTAODepthShader.vertexShader,
            fragmentShader: GTAODepthShader.fragmentShader,
            blending: NoBlending
        });
        this.depthRenderMaterial.uniforms.cameraNear.value = camera.near;
        this.depthRenderMaterial.uniforms.cameraFar.value = camera.far;

        this.copyMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(CopyUniforms),
            vertexShader: CopyShader.vertexShader,
            fragmentShader: CopyShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
            blendSrc: DstColorFactor,
            blendDst: ZeroFactor,
            blendEquation: AddEquation,
            blendSrcAlpha: DstAlphaFactor,
            blendDstAlpha: ZeroFactor,
            blendEquationAlpha: AddEquation
        });

        this.blendMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(GTAOBlendUniforms),
            vertexShader: GTAOBlendShader.vertexShader,
            fragmentShader: GTAOBlendShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
            blending: CustomBlending,
            blendSrc: DstColorFactor,
            blendDst: ZeroFactor,
            blendEquation: AddEquation,
            blendSrcAlpha: DstAlphaFactor,
            blendDstAlpha: ZeroFactor,
            blendEquationAlpha: AddEquation
        });

        this.fsQuad = new FullScreenQuad(null);

        this.originalClearColor = new Color();

        this.setGBuffer(parameters.depthTexture, parameters.normalTexture);

        if (aoParameters != null) {
            this.updateGtaoMaterial(aoParameters);
        }

        if (pdParameters != null) {
            this.updatePdMaterial(pdParameters);
        }
    }

    public function dispose() {
        this.gtaoNoiseTexture.dispose();
        this.pdNoiseTexture.dispose();
        this.normalRenderTarget.dispose();
        this.gtaoRenderTarget.dispose();
        this.pdRenderTarget.dispose();
        this.normalMaterial.dispose();
        this.pdMaterial.dispose();
        this.copyMaterial.dispose();
        this.depthRenderMaterial.dispose();
        this.fsQuad.dispose();
    }

    public function getGtaoMap():Texture {
        return this.pdRenderTarget.texture;
    }

    public function setGBuffer(depthTexture:Texture, normalTexture:Texture) {
        // ...
    }

    public function setSceneClipBox(box:Box3) {
        // ...
    }

    public function updateGtaoMaterial(parameters:Dynamic) {
        // ...
    }

    public function updatePdMaterial(parameters:Dynamic) {
        // ...
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        // ...
    }

    public function renderPass(renderer:WebGLRenderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float) {
        // ...
    }

    public function setSize(width:Int, height:Int) {
        // ...
    }

    public function overrideVisibility() {
        // ...
    }

    public function restoreVisibility() {
        // ...
    }

    public function generateNoise(size:Int = 64):DataTexture {
        // ...
    }
}

class GTAOPass {
    public static var OUTPUT = {
        Off: -1,
        Default: 0,
        Diffuse: 1,
        Depth: 2,
        Normal: 3,
        AO: 4,
        Denoise: 5
    };
}