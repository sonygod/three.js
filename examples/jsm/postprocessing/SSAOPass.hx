package three.js.examples.javascript.postprocessing;

import three.js.Core.*;
import three.js.math.*;
import three.js.renderers.WebGLRenderTarget;
import three.js.scenes.Scene;
import three.js.cameras.Camera;
import three.js.loaders.DataTexture;
import three.js.materials.MeshNormalMaterial;
import three.js.materials.ShaderMaterial;
import three.js.renderers.WebGLShader;
import three.js.utils.UniformsUtils;
import three.js.math.SimplexNoise;

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
    public var fsQuad:FullScreenQuad;
    public var originalClearColor:Color;
    public var normalRenderTarget:WebGLRenderTarget;
    public var ssaoRenderTarget:WebGLRenderTarget;
    public var blurRenderTarget:WebGLRenderTarget;
    public var ssaoMaterial:ShaderMaterial;
    public var normalMaterial:MeshNormalMaterial;
    public var blurMaterial:ShaderMaterial;
    public var depthRenderMaterial:ShaderMaterial;
    public var copyMaterial:ShaderMaterial;

    public function new(scene:Scene, camera:Camera, width:Int, height:Int, kernelSize:Int = 32) {
        super();
        this.width = width != null ? width : 512;
        this.height = height != null ? height : 512;
        this.clear = true;
        this.camera = camera;
        this.scene = scene;
        this.kernelRadius = 8;
        this.kernel = new Array<Vector3>();
        this.noiseTexture = null;
        this.output = 0;
        this.minDistance = 0.005;
        this.maxDistance = 0.1;
        this._visibilityCache = new Map<Dynamic, Bool>();

        generateSampleKernel(kernelSize);
        generateRandomKernelRotations();

        // depth texture
        var depthTexture:DataTexture = new DataTexture();
        depthTexture.format = DepthStencilFormat;
        depthTexture.type = UnsignedInt248Type;

        // normal render target with depth buffer
        normalRenderTarget = new WebGLRenderTarget(this.width, this.height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType,
            depthTexture: depthTexture
        });

        // ssao render target
        ssaoRenderTarget = new WebGLRenderTarget(this.width, this.height, { type: HalfFloatType });
        blurRenderTarget = ssaoRenderTarget.clone();

        // ssao material
        ssaoMaterial = new ShaderMaterial({
            defines: SSAOShader.defines,
            uniforms: UniformsUtils.clone(SSAOShader.uniforms),
            vertexShader: SSAOShader.vertexShader,
            fragmentShader: SSAOShader.fragmentShader,
            blending: NoBlending
        });
        ssaoMaterial.defines['KERNEL_SIZE'] = kernelSize;

        ssaoMaterial.uniforms['tNormal'].value = normalRenderTarget.texture;
        ssaoMaterial.uniforms['tDepth'].value = normalRenderTarget.depthTexture;
        ssaoMaterial.uniforms['tNoise'].value = noiseTexture;
        ssaoMaterial.uniforms['kernel'].value = kernel;
        ssaoMaterial.uniforms['cameraNear'].value = camera.near;
        ssaoMaterial.uniforms['cameraFar'].value = camera.far;
        ssaoMaterial.uniforms['resolution'].value.set(this.width, this.height);
        ssaoMaterial.uniforms['cameraProjectionMatrix'].value.copy(camera.projectionMatrix);
        ssaoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(camera.projectionMatrixInverse);

        // normal material
        normalMaterial = new MeshNormalMaterial();
        normalMaterial.blending = NoBlending;

        // blur material
        blurMaterial = new ShaderMaterial({
            defines: SSAOBlurShader.defines,
            uniforms: UniformsUtils.clone(SSAOBlurShader.uniforms),
            vertexShader: SSAOBlurShader.vertexShader,
            fragmentShader: SSAOBlurShader.fragmentShader
        });
        blurMaterial.uniforms['tDiffuse'].value = ssaoRenderTarget.texture;
        blurMaterial.uniforms['resolution'].value.set(this.width, this.height);

        // material for rendering the depth
        depthRenderMaterial = new ShaderMaterial({
            defines: SSAODepthShader.defines,
            uniforms: UniformsUtils.clone(SSAODepthShader.uniforms),
            vertexShader: SSAODepthShader.vertexShader,
            fragmentShader: SSAODepthShader.fragmentShader,
            blending: NoBlending
        });
        depthRenderMaterial.uniforms['tDepth'].value = normalRenderTarget.depthTexture;
        depthRenderMaterial.uniforms['cameraNear'].value = camera.near;
        depthRenderMaterial.uniforms['cameraFar'].value = camera.far;

        // material for rendering the content of a render target
        copyMaterial = new ShaderMaterial({
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

        fsQuad = new FullScreenQuad(null);
    }

    override public function dispose() {
        normalRenderTarget.dispose();
        ssaoRenderTarget.dispose();
        blurRenderTarget.dispose();

        normalMaterial.dispose();
        blurMaterial.dispose();
        copyMaterial.dispose();
        depthRenderMaterial.dispose();

        fsQuad.dispose();
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget /*, deltaTime:Float, maskActive:Bool*/) {
        // render normals and depth (honor only meshes, points and lines do not contribute to SSAO)
        overrideVisibility();
        renderOverride(renderer, normalMaterial, normalRenderTarget, 0x7777ff, 1.0);
        restoreVisibility();

        // render SSAO
        ssaoMaterial.uniforms['kernelRadius'].value = kernelRadius;
        ssaoMaterial.uniforms['minDistance'].value = minDistance;
        ssaoMaterial.uniforms['maxDistance'].value = maxDistance;
        renderPass(renderer, ssaoMaterial, ssaoRenderTarget);

        // render blur
        renderPass(renderer, blurMaterial, blurRenderTarget);

        // output result to screen
        switch (output) {
            case SSAOPass.OUTPUT.SSAO:
                copyMaterial.uniforms['tDiffuse'].value = ssaoRenderTarget.texture;
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Blur:
                copyMaterial.uniforms['tDiffuse'].value = blurRenderTarget.texture;
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Depth:
                renderPass(renderer, depthRenderMaterial, renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Normal:
                copyMaterial.uniforms['tDiffuse'].value = normalRenderTarget.texture;
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, renderToScreen ? null : writeBuffer);

                break;

            case SSAOPass.OUTPUT.Default:
                copyMaterial.uniforms['tDiffuse'].value = readBuffer.texture;
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, renderToScreen ? null : writeBuffer);

                copyMaterial.uniforms['tDiffuse'].value = blurRenderTarget.texture;
                copyMaterial.blending = CustomBlending;
                renderPass(renderer, copyMaterial, renderToScreen ? null : writeBuffer);

                break;

            default:
                Console.warn('THREE.SSAOPass: Unknown output type.');
        }
    }

    public function renderPass(renderer:WebGLRenderer, material:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int = null, clearAlpha:Float = 0.0) {
        // save original state
        originalClearColor.copy(renderer.getClearColor());
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);

        // setup pass state
        renderer.autoClear = false;
        if ((clearColor != null) && (clearColor != 0)) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha);
            renderer.clear();
        }

        fsQuad.material = material;
        fsQuad.render(renderer);

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function renderOverride(renderer:WebGLRenderer, overrideMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float) {
        renderer.getClearColor(originalClearColor);
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        clearColor = overrideMaterial.clearColor || clearColor;
        clearAlpha = overrideMaterial.clearAlpha || clearAlpha;

        if ((clearColor != null) && (clearColor != 0)) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha);
            renderer.clear();
        }

        scene.overrideMaterial = overrideMaterial;
        renderer.render(scene, camera);
        scene.overrideMaterial = null;

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function setSize(width:Int, height:Int) {
        this.width = width;
        this.height = height;

        ssaoRenderTarget.setSize(width, height);
        normalRenderTarget.setSize(width, height);
        blurRenderTarget.setSize(width, height);

        ssaoMaterial.uniforms['resolution'].value.set(width, height);
        ssaoMaterial.uniforms['cameraProjectionMatrix'].value.copy(camera.projectionMatrix);
        ssaoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(camera.projectionMatrixInverse);

        blurMaterial.uniforms['resolution'].value.set(width, height);
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

        noiseTexture = new DataTexture(data, width, height, RedFormat, FloatType);
        noiseTexture.wrapS = RepeatWrapping;
        noiseTexture.wrapT = RepeatWrapping;
        noiseTexture.needsUpdate = true;
    }

    public function overrideVisibility() {
        var scene:Scene = this.scene;
        var cache:Map<Dynamic, Bool> = this._visibilityCache;

        scene.traverse(function (object:Dynamic) {
            cache.set(object, object.visible);

            if (object.isPoints || object.isLine) object.visible = false;
        });
    }

    public function restoreVisibility() {
        var scene:Scene = this.scene;
        var cache:Map<Dynamic, Bool> = this._visibilityCache;

        scene.traverse(function (object:Dynamic) {
            var visible:Bool = cache.get(object);
            object.visible = visible;
        });

        cache.clear();
    }
}

class SSAOPass {
    public static inline var OUTPUT = {
        Default: 0,
        SSAO: 1,
        Blur: 2,
        Depth: 3,
        Normal: 4
    };
}