import js.three.AddEquation;
import js.three.Color;
import js.three.CustomBlending;
import js.three.DepthTexture;
import js.three.DstAlphaFactor;
import js.three.DstColorFactor;
import js.three.HalfFloatType;
import js.three.MeshNormalMaterial;
import js.three.NearestFilter;
import js.three.NoBlending;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.DepthStencilFormat;
import js.three.UnsignedInt248Type;
import js.three.Vector2;
import js.three.WebGLRenderTarget;
import js.three.ZeroFactor;
import three.Pass;
import three.FullScreenQuad;
import three.SAOShader;
import three.DepthLimitedBlurShader;
import three.BlurShaderUtils;
import three.CopyShader;

class SAOPass extends Pass {
    public var scene:js.three.Scene;
    public var camera:js.three.Camera;
    public var clear:Bool;
    public var needsSwap:Bool;
    public var originalClearColor:Color;
    public var _oldClearColor:Color;
    public var oldClearAlpha:Float;
    public var params:Dynamic;
    public var resolution:Vector2;
    public var saoRenderTarget:WebGLRenderTarget;
    public var blurIntermediateRenderTarget:WebGLRenderTarget;
    public var normalRenderTarget:WebGLRenderTarget;
    public var normalMaterial:MeshNormalMaterial;
    public var saoMaterial:ShaderMaterial;
    public var vBlurMaterial:ShaderMaterial;
    public var hBlurMaterial:ShaderMaterial;
    public var materialCopy:ShaderMaterial;
    public var fsQuad:FullScreenQuad;
    public var prevStdDev:Float;
    public var prevNumSamples:Int;

    public function new(scene:js.three.Scene, camera:js.three.Camera, resolution:Vector2 = null) {
        super();

        this.scene = scene;
        this.camera = camera;

        this.clear = true;
        this.needsSwap = false;

        this.originalClearColor = new Color();
        this._oldClearColor = new Color();
        this.oldClearAlpha = 1;

        this.params = {
            output: 0,
            saoBias: 0.5,
            saoIntensity: 0.18,
            saoScale: 1,
            saoKernelRadius: 100,
            saoMinResolution: 0,
            saoBlur: true,
            saoBlurRadius: 8,
            saoBlurStdDev: 4,
            saoBlurDepthCutoff: 0.01
        };

        this.resolution = resolution != null ? resolution : new Vector2(256, 256);

        this.saoRenderTarget = new WebGLRenderTarget(this.resolution.x, this.resolution.y, { type: HalfFloatType });
        this.blurIntermediateRenderTarget = this.saoRenderTarget.clone();

        var depthTexture = new DepthTexture();
        depthTexture.format = DepthStencilFormat;
        depthTexture.type = UnsignedInt248Type;

        this.normalRenderTarget = new WebGLRenderTarget(this.resolution.x, this.resolution.y, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType,
            depthTexture: depthTexture
        });

        this.normalMaterial = new MeshNormalMaterial();
        this.normalMaterial.blending = NoBlending;

        this.saoMaterial = new ShaderMaterial({
            defines: js.Boot.clone(SAOShader.defines),
            fragmentShader: SAOShader.fragmentShader,
            vertexShader: SAOShader.vertexShader,
            uniforms: UniformsUtils.clone(SAOShader.uniforms)
        });
        this.saoMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
        this.saoMaterial.uniforms['tDepth'].value = depthTexture;
        this.saoMaterial.uniforms['tNormal'].value = this.normalRenderTarget.texture;
        this.saoMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
        this.saoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);
        this.saoMaterial.uniforms['cameraProjectionMatrix'].value = this.camera.projectionMatrix;
        this.saoMaterial.blending = NoBlending;

        this.vBlurMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
            defines: js.Boot.clone(DepthLimitedBlurShader.defines),
            vertexShader: DepthLimitedBlurShader.vertexShader,
            fragmentShader: DepthLimitedBlurShader.fragmentShader
        });
        this.vBlurMaterial.defines['DEPTH_PACKING'] = 0;
        this.vBlurMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
        this.vBlurMaterial.uniforms['tDiffuse'].value = this.saoRenderTarget.texture;
        this.vBlurMaterial.uniforms['tDepth'].value = depthTexture;
        this.vBlurMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
        this.vBlurMaterial.blending = NoBlending;

        this.hBlurMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
            defines: js.Boot.clone(DepthLimitedBlurShader.defines),
            vertexShader: DepthLimitedBlurShader.vertexShader,
            fragmentShader: DepthLimitedBlurShader.fragmentShader
        });
        this.hBlurMaterial.defines['DEPTH_PACKING'] = 0;
        this.hBlurMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
        this.hBlurMaterial.uniforms['tDiffuse'].value = this.blurIntermediateRenderTarget.texture;
        this.hBlurMaterial.uniforms['tDepth'].value = depthTexture;
        this.hBlurMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
        this.hBlurMaterial.blending = NoBlending;

        this.materialCopy = new ShaderMaterial({
            uniforms: UniformsUtils.clone(CopyShader.uniforms),
            vertexShader: CopyShader.vertexShader,
            fragmentShader: CopyShader.fragmentShader,
            blending: NoBlending
        });
        this.materialCopy.transparent = true;
        this.materialCopy.depthTest = false;
        this.materialCopy.depthWrite = false;
        this.materialCopy.blending = CustomBlending;
        this.materialCopy.blendSrc = DstColorFactor;
        this.materialCopy.blendDst = ZeroFactor;
        this.materialCopy.blendEquation = AddEquation;
        this.materialCopy.blendSrcAlpha = DstAlphaFactor;
        this.materialCopy.blendDstAlpha = ZeroFactor;
        this.materialCopy.blendEquationAlpha = AddEquation;

        this.fsQuad = new FullScreenQuad(null);
    }

    public function render(renderer:js.three.WebGLRenderer, writeBuffer:js.three.WebGLRenderTarget, readBuffer:js.three.WebGLRenderTarget) {
        if (this.renderToScreen) {
            this.materialCopy.blending = NoBlending;
            this.materialCopy.uniforms['tDiffuse'].value = readBuffer.texture;
            this.materialCopy.needsUpdate = true;
            this.renderPass(renderer, this.materialCopy, null);
        }

        renderer.getClearColor(this._oldClearColor);
        this.oldClearAlpha = renderer.getClearAlpha();
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        this.saoMaterial.uniforms['bias'].value = this.params.saoBias;
        this.saoMaterial.uniforms['intensity'].value = this.params.saoIntensity;
        this.saoMaterial.uniforms['scale'].value = this.params.saoScale;
        this.saoMaterial.uniforms['kernelRadius'].value = this.params.saoKernelRadius;
        this.saoMaterial.uniforms['minResolution'].value = this.params.saoMinResolution;
        this.saoMaterial.uniforms['cameraNear'].value = this.camera.near;
        this.saoMaterial.uniforms['cameraFar'].value = this.camera.far;

        var depthCutoff = this.params.saoBlurDepthCutoff * (this.camera.far - this.camera.near);
        this.vBlurMaterial.uniforms['depthCutoff'].value = depthCutoff;
        this.hBlurMaterial.uniforms['depthCutoff'].value = depthCutoff;

        this.vBlurMaterial.uniforms['cameraNear'].value = this.camera.near;
        this.vBlurMaterial.uniforms['cameraFar'].value = this.camera.far;
        this.hBlurMaterial.uniforms['cameraNear'].value = this.camera.near;
        this.hBlurMaterial.uniforms['cameraFar'].value = this.camera.far;

        this.params.saoBlurRadius = Math.floor(this.params.saoBlurRadius);
        if ((this.prevStdDev !== this.params.saoBlurStdDev) || (this.prevNumSamples !== this.params.saoBlurRadius)) {
            BlurShaderUtils.configure(this.vBlurMaterial, this.params.saoBlurRadius, this.params.saoBlurStdDev, new Vector2(0, 1));
            BlurShaderUtils.configure(this.hBlurMaterial, this.params.saoBlurRadius, this.params.saoBlurStdDev, new Vector2(1, 0));
            this.prevStdDev = this.params.saoBlurStdDev;
            this.prevNumSamples = this.params.saoBlurRadius;
        }

        this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);

        this.renderPass(renderer, this.saoMaterial, this.saoRenderTarget, 0xffffff, 1.0);

        if (this.params.saoBlur) {
            this.renderPass(renderer, this.vBlurMaterial, this.blurIntermediateRenderTarget, 0xffffff, 1.0);
            this.renderPass(renderer, this.hBlurMaterial, this.saoRenderTarget, 0xffffff, 1.0);
        }

        var outputMaterial = this.materialCopy;

        if (this.params.output === SAOPass.OUTPUT.Normal) {
            this.materialCopy.uniforms['tDiffuse'].value = this.normalRenderTarget.texture;
            this.materialCopy.needsUpdate = true;
        } else {
            this.materialCopy.uniforms['tDiffuse'].value = this.saoRenderTarget.texture;
            this.materialCopy.needsUpdate = true;
        }

        if (this.params.output === SAOPass.OUTPUT.Default) {
            outputMaterial.blending = CustomBlending;
        } else {
            outputMaterial.blending = NoBlending;
        }

        this.renderPass(renderer, outputMaterial, this.renderToScreen ? null : readBuffer);

        renderer.setClearColor(this._oldClearColor, this.oldClearAlpha);
        renderer.autoClear = oldAutoClear;
    }

    public function renderPass(renderer:js.three.WebGLRenderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float) {
        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);

        renderer.autoClear = false;
        if (clearColor != null) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha != null ? clearAlpha : 0.0);
            renderer.clear();
        }

        this.fsQuad.material = passMaterial;
        this.fsQuad.render(renderer);

        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(this.originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function renderOverride(renderer:js.three.WebGLRenderer, overrideMaterial:MeshNormalMaterial, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float) {
        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        clearColor = overrideMaterial.clearColor != null ? overrideMaterial.clearColor : clearColor;
        clearAlpha = overrideMaterial.clearAlpha != null ? overrideMaterial.clearAlpha : clearAlpha;
        if (clearColor != null) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha != null ? clearAlpha : 0.0);
            renderer.clear();
        }

        this.scene.overrideMaterial = overrideMaterial;
        renderer.render(this.scene, this.camera);
        this.scene.overrideMaterial = null;

        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(this.originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function setSize(width:Float, height:Float) {
        this.saoRenderTarget.setSize(width, height);
        this.blurIntermediateRenderTarget.setSize(width, height);
        this.normalRenderTarget.setSize(width, height);

        this.saoMaterial.uniforms['size'].value.set(width, height);
        this.saoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);
        this.saoMaterial.uniforms['cameraProjectionMatrix'].value = this.camera.projectionMatrix;
        this.saoMaterial.needsUpdate = true;

        this.vBlurMaterial.uniforms['size'].value.set(width, height);
        this.vBlurMaterial.needsUpdate = true;

        this.hBlurMaterial.uniforms['size'].value.set(width, height);
        this.hBlurMaterial.needsUpdate = true;
    }

    public function dispose() {
        this.saoRenderTarget.dispose();
        this.blurIntermediateRenderTarget.dispose();
        this.normalRenderTarget.dispose();

        this.normalMaterial.dispose();
        this.saoMaterial.dispose();
        this.vBlurMaterial.dispose();
        this.hBlurMaterial.dispose();
        this.materialCopy.dispose();

        this.fsQuad.dispose();
    }

    public static var OUTPUT:Dynamic = {
        'Default': 0,
        'SAO': 1,
        'Normal': 2
    };
}