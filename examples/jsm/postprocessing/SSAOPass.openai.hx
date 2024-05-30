package three.js.examples.javascript.postprocessing;

import three.Core;
import three.DataTexture;
import three.DepthTexture;
import three.FloatType;
import three.HalfFloatType;
import three.MathUtils;
import three.MeshNormalMaterial;
import three.NearestFilter;
import three.NoBlending;
import three.RedFormat;
import three.RepeatWrapping;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector3;
import three.WebGLRenderTarget;

import postprocessing.Pass;
import math.SimplexNoise;

class SSAOPass extends Pass {
    public var width:Int;
    public var height:Int;

    public var clear:Bool;
    public var camera:Camera;
    public var scene:Scene;

    public var kernelRadius:Float;
    public var kernel:Array<Vector3>;
    public var noiseTexture:DataTexture;
    public var output:Int;

    public var minDistance:Float;
    public var maxDistance:Float;

    public var _visibilityCache:Map<Dynamic, Bool>;

    public function new(scene:Scene, camera:Camera, width:Int = 512, height:Int = 512, kernelSize:Int = 32) {
        super();

        this.width = width;
        this.height = height;

        this.clear = true;

        this.camera = camera;
        this.scene = scene;

        this.kernelRadius = 8;
        this.kernel = [];
        this.noiseTexture = null;
        this.output = 0;

        this.minDistance = 0.005;
        this.maxDistance = 0.1;

        this._visibilityCache = new Map();

        this.generateSampleKernel(kernelSize);
        this.generateRandomKernelRotations();

        // depth texture
        var depthTexture:DepthTexture = new DepthTexture();
        depthTexture.format = DepthStencilFormat;
        depthTexture.type = UnsignedInt248Type;

        // normal render target with depth buffer
        this.normalRenderTarget = new WebGLRenderTarget(width, height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType,
            depthTexture: depthTexture
        });

        // ssao render target
        this.ssaoRenderTarget = new WebGLRenderTarget(width, height, { type: HalfFloatType });

        this.blurRenderTarget = this.ssaoRenderTarget.clone();

        // ssao material
        this.ssaoMaterial = new ShaderMaterial({
            defines: SSAOShader.defines.clone(),
            uniforms: UniformsUtils.clone(SSAOShader.uniforms),
            vertexShader: SSAOShader.vertexShader,
            fragmentShader: SSAOShader.fragmentShader,
            blending: NoBlending
        });

        this.ssaoMaterial.defines.set('KERNEL_SIZE', kernelSize);

        this.ssaoMaterial.uniforms.get('tNormal').value = this.normalRenderTarget.texture;
        this.ssaoMaterial.uniforms.get('tDepth').value = this.normalRenderTarget.depthTexture;
        this.ssaoMaterial.uniforms.get('tNoise').value = this.noiseTexture;
        this.ssaoMaterial.uniforms.get('kernel').value = this.kernel;
        this.ssaoMaterial.uniforms.get('cameraNear').value = this.camera.near;
        this.ssaoMaterial.uniforms.get('cameraFar').value = this.camera.far;
        this.ssaoMaterial.uniforms.get('resolution').value.set(width, height);
        this.ssaoMaterial.uniforms.get('cameraProjectionMatrix').value.copy(this.camera.projectionMatrix);
        this.ssaoMaterial.uniforms.get('cameraInverseProjectionMatrix').value.copy(this.camera.projectionMatrixInverse);

        // normal material
        this.normalMaterial = new MeshNormalMaterial();
        this.normalMaterial.blending = NoBlending;

        // blur material
        this.blurMaterial = new ShaderMaterial({
            defines: SSAOBlurShader.defines.clone(),
            uniforms: UniformsUtils.clone(SSAOBlurShader.uniforms),
            vertexShader: SSAOBlurShader.vertexShader,
            fragmentShader: SSAOBlurShader.fragmentShader
        });
        this.blurMaterial.uniforms.get('tDiffuse').value = this.ssaoRenderTarget.texture;
        this.blurMaterial.uniforms.get('resolution').value.set(width, height);

        // material for rendering the depth
        this.depthRenderMaterial = new ShaderMaterial({
            defines: SSAODepthShader.defines.clone(),
            uniforms: UniformsUtils.clone(SSAODepthShader.uniforms),
            vertexShader: SSAODepthShader.vertexShader,
            fragmentShader: SSAODepthShader.fragmentShader,
            blending: NoBlending
        });
        this.depthRenderMaterial.uniforms.get('tDepth').value = this.normalRenderTarget.depthTexture;
        this.depthRenderMaterial.uniforms.get('cameraNear').value = this.camera.near;
        this.depthRenderMaterial.uniforms.get('cameraFar').value = this.camera.far;

        // material for rendering the content of a render target
        this.copyMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(CopyShader.uniforms),
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

        this.fsQuad = new FullScreenQuad(null);

        this.originalClearColor = new Color();
    }

    public function dispose() {
        this.normalRenderTarget.dispose();
        this.ssaoRenderTarget.dispose();
        this.blurRenderTarget.dispose();

        this.normalMaterial.dispose();
        this.blurMaterial.dispose();
        this.copyMaterial.dispose();
        this.depthRenderMaterial.dispose();

        this.fsQuad.dispose();
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget/*, deltaTime:Float, maskActive:Bool*/) {
        // render normals and depth (honor only meshes, points and lines do not contribute to SSAO)
        this.overrideVisibility();
        this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);
        this.restoreVisibility();

        // render SSAO
        this.ssaoMaterial.uniforms.get('kernelRadius').value = this.kernelRadius;
        this.ssaoMaterial.uniforms.get('minDistance').value = this.minDistance;
        this.ssaoMaterial.uniforms.get('maxDistance').value = this.maxDistance;
        this.renderPass(renderer, this.ssaoMaterial, this.ssaoRenderTarget);

        // render blur
        this.renderPass(renderer, this.blurMaterial, this.blurRenderTarget);

        // output result to screen
        switch (this.output) {
            case OUTPUT_SSAO:
                this.copyMaterial.uniforms.get('tDiffuse').value = this.ssaoRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case OUTPUT_Blur:
                this.copyMaterial.uniforms.get('tDiffuse').value = this.blurRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case OUTPUT_Depth:
                this.renderPass(renderer, this.depthRenderMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case OUTPUT_Normal:
                this.copyMaterial.uniforms.get('tDiffuse').value = this.normalRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case OUTPUT_Default:
                this.copyMaterial.uniforms.get('tDiffuse').value = readBuffer.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                this.copyMaterial.uniforms.get('tDiffuse').value = this.blurRenderTarget.texture;
                this.copyMaterial.blending = CustomBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            default:
                Console.warn('THREE.SSAOPass: Unknown output type.');
        }
    }

    public function renderPass(renderer:WebGLRenderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Null<Int>, clearAlpha:Null<Float>) {
        // save original state
        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha:Float = renderer.getClearAlpha();
        var originalAutoClear:Bool = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);

        // setup pass state
        renderer.autoClear = false;
        if (clearColor != null) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha || 0.0);
            renderer.clear();
        }

        this.fsQuad.material = passMaterial;
        this.fsQuad.render(renderer);

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(this.originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function renderOverride(renderer:WebGLRenderer, overrideMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Null<Int>, clearAlpha:Null<Float>) {
        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha:Float = renderer.getClearAlpha();
        var originalAutoClear:Bool = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        clearColor = overrideMaterial.clearColor || clearColor;
        clearAlpha = overrideMaterial.clearAlpha || clearAlpha;

        if (clearColor != null) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha || 0.0);
            renderer.clear();
        }

        this.scene.overrideMaterial = overrideMaterial;
        renderer.render(this.scene, this.camera);
        this.scene.overrideMaterial = null;

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(this.originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function setSize(width:Int, height:Int) {
        this.width = width;
        this.height = height;

        this.ssaoRenderTarget.setSize(width, height);
        this.normalRenderTarget.setSize(width, height);
        this.blurRenderTarget.setSize(width, height);

        this.ssaoMaterial.uniforms.get('resolution').value.set(width, height);
        this.ssaoMaterial.uniforms.get('cameraProjectionMatrix').value.copy(this.camera.projectionMatrix);
        this.ssaoMaterial.uniforms.get('cameraInverseProjectionMatrix').value.copy(this.camera.projectionMatrixInverse);

        this.blurMaterial.uniforms.get('resolution').value.set(width, height);
    }

    public function generateSampleKernel(kernelSize:Int) {
        var kernel:Array<Vector3> = this.kernel;

        for (i in 0...kernelSize) {
            var sample:Vector3 = new Vector3();
            sample.x = (Math.random() * 2) - 1;
            sample.y = (Math.random() * 2) - 1;
            sample.z = Math.random();

            sample.normalize();

            var scale:Float = i / kernelSize;
            scale = MathUtils.lerp(0.1, 1, scale * scale);
            sample.multiplyScalar(scale);

            kernel.push(sample);
        }
    }

    public function generateRandomKernelRotations() {
        var width:Int = 4;
        var height:Int = 4;

        var simplex:SimplexNoise = new SimplexNoise();

        var size:Int = width * height;
        var data:Array<Float> = new Array<Float>();

        for (i in 0...size) {
            var x:Float = (Math.random() * 2) - 1;
            var y:Float = (Math.random() * 2) - 1;
            var z:Float = 0;

            data[i] = simplex.noise3d(x, y, z);
        }

        this.noiseTexture = new DataTexture(data, width, height, RedFormat, FloatType);
        this.noiseTexture.wrapS = RepeatWrapping;
        this.noiseTexture.wrapT = RepeatWrapping;
        this.noiseTexture.needsUpdate = true;
    }

    public function overrideVisibility() {
        var scene:Scene = this.scene;
        var cache:Map<Dynamic, Bool> = this._visibilityCache;

        scene.traverse(function(object:Dynamic) {
            cache.set(object, object.visible);

            if (object.isPoints || object.isLine) object.visible = false;
        });
    }

    public function restoreVisibility() {
        var scene:Scene = this.scene;
        var cache:Map<Dynamic, Bool> = this._visibilityCache;

        scene.traverse(function(object:Dynamic) {
            var visible:Bool = cache.get(object);
            object.visible = visible;
        });

        cache.clear();
    }
}

class OUTPUT {
    public static inline var Default:Int = 0;
    public static inline var SSAO:Int = 1;
    public static inline var Blur:Int = 2;
    public static inline var Depth:Int = 3;
    public static inline var Normal:Int = 4;
}