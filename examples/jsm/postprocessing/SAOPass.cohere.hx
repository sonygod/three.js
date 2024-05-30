import js.three.AddEquation;
import js.three.Color;
import js.three.CustomBlending;
import js.three.DepthStencilFormat;
import js.three.DepthTexture;
import js.three.DstAlphaFactor;
import js.three.DstColorFactor;
import js.three.HalfFloatType;
import js.three.MeshNormalMaterial;
import js.three.NearestFilter;
import js.three.NoBlending;
import js.three.Pass;
import js.three.SAOPass.OUTPUT;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.UnsignedInt248Type;
import js.three.Vector2;
import js.three.WebGLRenderTarget;
import js.three.ZeroFactor;

import js.three.shaders.CopyShader;
import js.three.shaders.DepthLimitedBlurShader;
import js.three.shaders.SAOShader;

class SAOPass extends Pass {
    public var scene:Dynamic;
    public var camera:Dynamic;
    public var clear:Bool;
    public var needsSwap:Bool;
    public var originalClearColor:Color;
    public var _oldClearColor:Color;
    public var oldClearAlpha:Float;
    public var params:Dynamic;
    public var resolution:Vector2;
    public var saoRenderTarget:WebGLRenderTarget;
    public var blurIntermediateRenderTarget:WebGLRenderTarget;
    public var depthTexture:DepthTexture;
    public var normalRenderTarget:WebGLRenderTarget;
    public var normalMaterial:MeshNormalMaterial;
    public var saoMaterial:ShaderMaterial;
    public var vBlurMaterial:ShaderMaterial;
    public var hBlurMaterial:ShaderMaterial;
    public var materialCopy:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(scene:Dynamic, camera:Dynamic, resolution:Vector2 = new Vector2(256, 256)) {
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
        this.resolution = new Vector2(resolution.x, resolution.y);
        this.saoRenderTarget = new WebGLRenderTarget(this.resolution.x, this.resolution.y, { type: HalfFloatType });
        this.blurIntermediateRenderTarget = this.saoRenderTarget.clone();
        this.depthTexture = new DepthTexture();
        this.depthTexture.format = DepthStencilFormat;
        this.depthTexture.type = UnsignedInt248Type;
        this.normalRenderTarget = new WebGLRenderTarget(this.resolution.x, this.resolution.y, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType,
            depthTexture: this.depthTexture
        });
        this.normalMaterial = new MeshNormalMaterial();
        this.normalMaterial.blending = NoBlending;
        this.saoMaterial = new ShaderMaterial({
            defines: { ...SAOShader.defines },
            fragmentShader: SAOShader.fragmentShader,
            vertexShader: SAOShader.vertexShader,
            uniforms: UniformsUtils.clone(SAOShader.uniforms)
        });
        this.saoMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
        this.saoMaterial.uniforms['tDepth'].value = this.depthTexture;
        this.saoMaterial.uniforms['tNormal'].value = this.normalRenderTarget.texture;
        this.saoMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
        this.saoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);
        this.saoMaterial.uniforms['cameraProjectionMatrix'].value = this.camera.projectionMatrix;
        this.saoMaterial.blending = NoBlending;
        this.vBlurMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
            defines: { ...DepthLimitedBlurShader.defines },
            vertexShader: DepthLimitedBlurShader.vertexShader,
            fragmentShader: DepthLimitedBlurShader.fragmentShader
        });
        this.vBlurMaterial.defines['DEPTH_PACKING'] = 0;
        this.vBlurMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
        this.vBlurMaterial.uniforms['tDiffuse'].value = this.saoRenderTarget.texture;
        this.vBlurMaterial.uniforms['tDepth'].value = this.depthTexture;
        this.vBlurMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
        this.vBlurMaterial.blending = NoBlending;
        this.hBlurMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
            defines: { ...DepthLimitedBlurShader.defines },
            vertexShader: DepthLimitedBlurShader.vertexShader,
            fragmentShader: DepthLimitedBlurShader.fragmentShader
        });
        this.hBlurMaterial.defines['DEPTH_PACKING'] = 0;
        this.hBlurMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
        this.hBlurMaterial.uniforms['tDiffuse'].value = this.blurIntermediateRenderTarget.texture;
        this.hBlurMaterial.uniforms['tDepth'].value = this.depthTexture;
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

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
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
        // this.saoMaterial.uniforms['randomSeed'].value = Math.random();
        var depthCutoff = this.params.saoBlurDepthCutoff * (this.camera.far - this.camera.near);
        this.vBlurMaterial.uniforms['depthCutoff'].value = depthCutoff;
        this.hBlurMaterial.uniforms['depthCutoff'].value = depthCutoff;
        this.vBlurMaterial.uniforms['cameraNear'].value = this.camera.near;
        this.vBlurMaterial.uniforms['cameraFar'].value = this.camera.far;
        this.hBlurMaterial.uniforms['cameraNear'].value = this.camera.near;
        this.hBlurMaterial.uniforms['cameraFar'].value = this.camera.far;
        this.params.saoBlurRadius = Std.int(this.params.saoBlurRadius);
        if (this.prevStdDev != this.params.saoBlurStdDev || this.prevNumSamples != this.params.saoBlurRadius) {
            BlurShaderUtils.configure(this.vBlurMaterial, this.params.saoBlurRadius, this.params.saoBlurStdDev, new Vector2(0, 1));
            BlurShaderUtils.configure(this.hBlurMaterial, this.params.saoBlurRadius, this.params.saoBlurStdDev, new Vector2(1, 0));
            this.prevStdDev = this.params.saoBlurStdDev;
            this.prevNumSamples = this.params.saoBlurRadius;
        }
        // render normal and depth
        this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);
        // Rendering SAO texture
        this.renderPass(renderer, this.saoMaterial, this.saoRenderTarget, 0xffffff, 1.0);
        // Blurring SAO texture
        if (this.params.saoBlur) {
            this.renderPass(renderer, this.vBlurMaterial, this.blurIntermediateRenderTarget, 0xffffff, 1.0);
            this.renderPass(renderer, this.hBlurMaterial, this.saoRenderTarget, 0xffffff, 1.0);
        }
        var outputMaterial = this.materialCopy;
        // Setting up SAO rendering
        if (this.params.output == SAOPass.OUTPUT.Normal) {
            this.materialCopy.uniforms['tDiffuse'].value = this.normalRenderTarget.texture;
            this.materialCopy.needsUpdate = true;
        } else {
            this.materialCopy.uniforms['tDiffuse'].value = this.saoRenderTarget.texture;
            this.materialCopy.needsUpdate = true;
        }
        // Blending depends on output
        if (this.params.output == SAOPass.OUTPUT.Default) {
            outputMaterial.blending = CustomBlending;
        } else {
            outputMaterial.blending = NoBlending;
        }
        // Rendering SAOPass result on top of previous pass
        this.renderPass(renderer, outputMaterial, this.renderToScreen ? null : readBuffer);
        renderer.setClearColor(this._oldClearColor, this.oldClearAlpha);
        renderer.autoClear = oldAutoClear;
    }

    public function renderPass(renderer:Dynamic, passMaterial:Dynamic, renderTarget:Dynamic, clearColor:Float, clearAlpha:Float) {
        // save original state
        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;
        renderer.setRenderTarget(renderTarget);
        // setup pass state
        renderer.autoClear = false;
        if (clearColor != null && clearColor != null) {
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

    public function renderOverride(renderer:Dynamic, overrideMaterial:Dynamic, renderTarget:Dynamic, clearColor:Float, clearAlpha:Float) {
        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;
        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;
        clearColor = overrideMaterial.clearColor || clearColor;
        clearAlpha = overrideMaterial.clearAlpha || clearAlpha;
        if (clearColor != null && clearColor != null) {
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
}

class OUTPUT {
    public static var Default:Int = 0;
    public static var SAO:Int = 1;
    public static var Normal:Int = 2;
}