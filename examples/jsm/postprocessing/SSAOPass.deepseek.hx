import three.AddEquation;
import three.Color;
import three.CustomBlending;
import three.DataTexture;
import three.DepthTexture;
import three.DstAlphaFactor;
import three.DstColorFactor;
import three.FloatType;
import three.HalfFloatType;
import three.MathUtils;
import three.MeshNormalMaterial;
import three.NearestFilter;
import three.NoBlending;
import three.RedFormat;
import three.DepthStencilFormat;
import three.UnsignedInt248Type;
import three.RepeatWrapping;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector3;
import three.WebGLRenderTarget;
import three.ZeroFactor;

import Pass.Pass;
import Pass.FullScreenQuad;
import math.SimplexNoise;
import shaders.SSAOShader;
import shaders.SSAOBlurShader;
import shaders.SSAODepthShader;
import shaders.CopyShader;

class SSAOPass extends Pass {

    public function new(scene:Scene, camera:Camera, width:Int, height:Int, kernelSize:Int = 32) {

        super();

        this.width = (width !== undefined) ? width : 512;
        this.height = (height !== undefined) ? height : 512;

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

        var depthTexture = new DepthTexture();
        depthTexture.format = DepthStencilFormat;
        depthTexture.type = UnsignedInt248Type;

        this.normalRenderTarget = new WebGLRenderTarget(this.width, this.height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType,
            depthTexture: depthTexture
        });

        this.ssaoRenderTarget = new WebGLRenderTarget(this.width, this.height, {type: HalfFloatType});

        this.blurRenderTarget = this.ssaoRenderTarget.clone();

        this.ssaoMaterial = new ShaderMaterial({
            defines: SSAOShader.defines,
            uniforms: UniformsUtils.clone(SSAOShader.uniforms),
            vertexShader: SSAOShader.vertexShader,
            fragmentShader: SSAOShader.fragmentShader,
            blending: NoBlending
        });

        this.ssaoMaterial.defines['KERNEL_SIZE'] = kernelSize;

        this.ssaoMaterial.uniforms['tNormal'].value = this.normalRenderTarget.texture;
        this.ssaoMaterial.uniforms['tDepth'].value = this.normalRenderTarget.depthTexture;
        this.ssaoMaterial.uniforms['tNoise'].value = this.noiseTexture;
        this.ssaoMaterial.uniforms['kernel'].value = this.kernel;
        this.ssaoMaterial.uniforms['cameraNear'].value = this.camera.near;
        this.ssaoMaterial.uniforms['cameraFar'].value = this.camera.far;
        this.ssaoMaterial.uniforms['resolution'].value.set(this.width, this.height);
        this.ssaoMaterial.uniforms['cameraProjectionMatrix'].value.copy(this.camera.projectionMatrix);
        this.ssaoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);

        this.normalMaterial = new MeshNormalMaterial();
        this.normalMaterial.blending = NoBlending;

        this.blurMaterial = new ShaderMaterial({
            defines: SSAOBlurShader.defines,
            uniforms: UniformsUtils.clone(SSAOBlurShader.uniforms),
            vertexShader: SSAOBlurShader.vertexShader,
            fragmentShader: SSAOBlurShader.fragmentShader
        });
        this.blurMaterial.uniforms['tDiffuse'].value = this.ssaoRenderTarget.texture;
        this.blurMaterial.uniforms['resolution'].value.set(this.width, this.height);

        this.depthRenderMaterial = new ShaderMaterial({
            defines: SSAODepthShader.defines,
            uniforms: UniformsUtils.clone(SSAODepthShader.uniforms),
            vertexShader: SSAODepthShader.vertexShader,
            fragmentShader: SSAODepthShader.fragmentShader,
            blending: NoBlending
        });
        this.depthRenderMaterial.uniforms['tDepth'].value = this.normalRenderTarget.depthTexture;
        this.depthRenderMaterial.uniforms['cameraNear'].value = this.camera.near;
        this.depthRenderMaterial.uniforms['cameraFar'].value = this.camera.far;

        this.copyMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(CopyShader.uniforms),
            vertexShader: CopyShader.vertexShader,
            fragmentShader: CopyShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
            blending: AddEquation,
            blendingSrcAlpha: DstAlphaFactor,
            blendingDstAlpha: ZeroFactor,
            blendingEquationAlpha: AddEquation
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

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {

        this.overrideVisibility();
        this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);
        this.restoreVisibility();

        this.ssaoMaterial.uniforms['kernelRadius'].value = this.kernelRadius;
        this.ssaoMaterial.uniforms['minDistance'].value = this.minDistance;
        this.ssaoMaterial.uniforms['maxDistance'].value = this.maxDistance;
        this.renderPass(renderer, this.ssaoMaterial, this.ssaoRenderTarget);

        this.renderPass(renderer, this.blurMaterial, this.blurRenderTarget);

        switch (this.output) {

            case SSAOPass.OUTPUT.SSAO:

                this.copyMaterial.uniforms['tDiffuse'].value = this.ssaoRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Blur:

                this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Depth:

                this.renderPass(renderer, this.depthRenderMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Normal:

                this.copyMaterial.uniforms['tDiffuse'].value = this.normalRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Default:

                this.copyMaterial.uniforms['tDiffuse'].value = readBuffer.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget.texture;
                this.copyMaterial.blending = CustomBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                break;

            default:
                trace('THREE.SSAOPass: Unknown output type.');

        }

    }

    public function renderPass(renderer:Renderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float) {

        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        clearColor = passMaterial.clearColor || clearColor;
        clearAlpha = passMaterial.clearAlpha || clearAlpha;

        if ((clearColor !== undefined) && (clearColor !== null)) {

            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha || 0.0);
            renderer.clear();

        }

        this.fsQuad.material = passMaterial;
        this.fsQuad.render(renderer);

        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(this.originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);

    }

    public function renderOverride(renderer:Renderer, overrideMaterial:Material, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float) {

        renderer.getClearColor(this.originalClearColor);
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        clearColor = overrideMaterial.clearColor || clearColor;
        clearAlpha = overrideMaterial.clearAlpha || clearAlpha;

        if ((clearColor !== undefined) && (clearColor !== null)) {

            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha || 0.0);
            renderer.clear();

        }

        this.scene.overrideMaterial = overrideMaterial;
        renderer.render(this.scene, this.camera);
        this.scene.overrideMaterial = null;

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

        this.ssaoMaterial.uniforms['resolution'].value.set(width, height);
        this.ssaoMaterial.uniforms['cameraProjectionMatrix'].value.copy(this.camera.projectionMatrix);
        this.ssaoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);

        this.blurMaterial.uniforms['resolution'].value.set(width, height);

    }

    public function generateSampleKernel(kernelSize:Int) {

        var kernel = this.kernel;

        for (i in 0...kernelSize) {

            var sample = new Vector3();
            sample.x = (Math.random() * 2) - 1;
            sample.y = (Math.random() * 2) - 1;
            sample.z = Math.random();

            sample.normalize();

            var scale = i / kernelSize;
            scale = MathUtils.lerp(0.1, 1, scale * scale);
            sample.multiplyScalar(scale);

            kernel.push(sample);

        }

    }

    public function generateRandomKernelRotations() {

        var width = 4, height = 4;

        var simplex = new SimplexNoise();

        var size = width * height;
        var data = new Float32Array(size);

        for (i in 0...size) {

            var x = (Math.random() * 2) - 1;
            var y = (Math.random() * 2) - 1;
            var z = 0;

            data[i] = simplex.noise3d(x, y, z);

        }

        this.noiseTexture = new DataTexture(data, width, height, RedFormat, FloatType);
        this.noiseTexture.wrapS = RepeatWrapping;
        this.noiseTexture.wrapT = RepeatWrapping;
        this.noiseTexture.needsUpdate = true;

    }

    public function overrideVisibility() {

        var scene = this.scene;
        var cache = this._visibilityCache;

        scene.traverse(function(object) {

            cache.set(object, object.visible);

            if (object.isPoints || object.isLine) object.visible = false;

        });

    }

    public function restoreVisibility() {

        var scene = this.scene;
        var cache = this._visibilityCache;

        scene.traverse(function(object) {

            var visible = cache.get(object);
            object.visible = visible;

        });

        cache.clear();

    }

}

SSAOPass.OUTPUT = {
    'Default': 0,
    'SSAO': 1,
    'Blur': 2,
    'Depth': 3,
    'Normal': 4
};