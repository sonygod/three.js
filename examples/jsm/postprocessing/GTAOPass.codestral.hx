import three.AddEquation;
import three.Color;
import three.CustomBlending;
import three.DataTexture;
import three.DepthTexture;
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

import postprocessing.Pass;
import postprocessing.FullScreenQuad;
import shaders.GTAOShader;
import shaders.PoissonDenoiseShader;
import shaders.CopyShader;
import math.SimplexNoise;

class GTAOPass extends Pass {

    public var width:Int;
    public var height:Int;
    public var clear:Bool;
    public var camera:Camera;
    public var scene:Scene;
    public var output:Int;
    public var _renderGBuffer:Bool;
    public var _visibilityCache:Map<Object, Bool>;
    public var blendIntensity:Float;

    public var pdRings:Float;
    public var pdRadiusExponent:Float;
    public var pdSamples:Int;

    public var gtaoNoiseTexture:DataTexture;
    public var pdNoiseTexture:DataTexture;

    public var gtaoRenderTarget:WebGLRenderTarget;
    public var pdRenderTarget:WebGLRenderTarget;

    public var gtaoMaterial:ShaderMaterial;
    public var normalMaterial:MeshNormalMaterial;
    public var pdMaterial:ShaderMaterial;
    public var depthRenderMaterial:ShaderMaterial;
    public var copyMaterial:ShaderMaterial;
    public var blendMaterial:ShaderMaterial;

    public var fsQuad:FullScreenQuad;

    public var originalClearColor:Color;

    public function new(scene:Scene, camera:Camera, width:Int = 512, height:Int = 512, parameters:Object = null, aoParameters:Object = null, pdParameters:Object = null) {
        super();

        this.width = width;
        this.height = height;
        this.clear = true;
        this.camera = camera;
        this.scene = scene;
        this.output = 0;
        this._renderGBuffer = true;
        this._visibilityCache = new Map<Object, Bool>();
        this.blendIntensity = 1.0;

        this.pdRings = 2.0;
        this.pdRadiusExponent = 2.0;
        this.pdSamples = 16;

        this.gtaoNoiseTexture = GTAOShader.generateMagicSquareNoise();
        this.pdNoiseTexture = this.generateNoise();

        this.gtaoRenderTarget = new WebGLRenderTarget(this.width, this.height, { type: HalfFloatType });
        this.pdRenderTarget = this.gtaoRenderTarget.clone();

        this.gtaoMaterial = new ShaderMaterial({
            defines: Object.assign({}, GTAOShader.defines),
            uniforms: UniformsUtils.clone(GTAOShader.uniforms),
            vertexShader: GTAOShader.vertexShader,
            fragmentShader: GTAOShader.fragmentShader,
            blending: NoBlending,
            depthTest: false,
            depthWrite: false,
        });
        // ... rest of the constructor
    }

    public function dispose() {
        // ... dispose method
    }

    public function get gtaoMap() {
        return this.pdRenderTarget.texture;
    }

    public function setGBuffer(depthTexture:DepthTexture, normalTexture:Texture) {
        // ... setGBuffer method
    }

    public function setSceneClipBox(box:Box3) {
        // ... setSceneClipBox method
    }

    public function updateGtaoMaterial(parameters:Object) {
        // ... updateGtaoMaterial method
    }

    public function updatePdMaterial(parameters:Object) {
        // ... updatePdMaterial method
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        // ... render method
    }

    public function renderPass(renderer:WebGLRenderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int = null, clearAlpha:Float = null) {
        // ... renderPass method
    }

    public function renderOverride(renderer:WebGLRenderer, overrideMaterial:Material, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float) {
        // ... renderOverride method
    }

    public function setSize(width:Int, height:Int) {
        // ... setSize method
    }

    public function overrideVisibility() {
        // ... overrideVisibility method
    }

    public function restoreVisibility() {
        // ... restoreVisibility method
    }

    public function generateNoise(size:Int = 64):DataTexture {
        // ... generateNoise method
    }
}

@:enum
enum OUTPUT {
    Off = -1;
    Default = 0;
    Diffuse = 1;
    Depth = 2;
    Normal = 3;
    AO = 4;
    Denoise = 5;
}

class GTAOPass {
    public static var OUTPUT:OUTPUT;
}