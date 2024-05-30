import h3d.Math3D;
import h3d.ShaderMaterial;
import h3d.Texture;
import h3d.WebGLRenderTarget;

class GTAOPass {
    public var width:Int;
    public var height:Int;
    public var clear:Bool;
    public var camera:Camera;
    public var scene:Scene;
    public var output:Int;
    private var _renderGBuffer:Bool;
    private var _visibilityCache:Map<DisplayObject,Bool>;
    public var blendIntensity:Float;

    public var pdRings:Float;
    public var pdRadiusExponent:Float;
    public var pdSamples:Int;

    public var gtaoNoiseTexture:Texture;
    public var pdNoiseTexture:Texture;

    public var gtaoRenderTarget:WebGLRenderTarget;
    public var pdRenderTarget:WebGLRenderTarget;

    public var gtaoMaterial:ShaderMaterial;
    public var normalMaterial:ShaderMaterial;
    public var pdMaterial:ShaderMaterial;
    public var depthRenderMaterial:ShaderMaterial;
    public var copyMaterial:ShaderMaterial;
    public var blendMaterial:ShaderMaterial;

    public var fsQuad:FullScreenQuad;

    public var originalClearColor:Color;

    public function new(scene:Scene, camera:Camera, ?width:Int, ?height:Int, ?parameters, ?aoParameters, ?pdParameters) {
        super();

        this.width = width != null ? width : 512;
        this.height = height != null ? height : 512;
        this.clear = true;
        this.camera = camera;
        this.scene = scene;
        this.output = 0;
        this._renderGBuffer = true;
        this._visibilityCache = new Map();
        this.blendIntensity = 1.0;

        this.pdRings = 2.0;
        this.pdRadiusExponent = 2.0;
        this.pdSamples = 16;

        this.gtaoNoiseTexture = generateMagicSquareNoise();
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
        this.gtaoMaterial.defines.PERSPECTIVE_CAMERA = this.camera.isPerspectiveCamera ? 1 : 0;
        this.gtaoMaterial.uniforms.tNoise.value = this.gtaoNoiseTexture;
        this.gtaoMaterial.uniforms.resolution.value.set(this.width, this.height);
        this.gtaoMaterial.uniforms.cameraNear.value = this.camera.near;
        this.gtaoMaterial.uniforms.cameraFar.value = this.camera.far;

        this.normalMaterial = new MeshNormalMaterial();
        this.normalMaterial.blending = NoBlending;

        this.pdMaterial = new ShaderMaterial({
            defines: Object.assign({}, PoissonDenoiseShader.defines),
            uniforms: UniformsUtils.clone(PoissonDenoiseShader.uniforms),
            vertexShader: PoissonDenoiseShader.vertexShader,
            fragmentShader: PoissonDenoiseShader.fragmentShader,
            depthTest: false,
            depthWrite: false,
        });
        this.pdMaterial.uniforms.tDiffuse.value = this.gtaoRenderTarget.texture;
        this.pdMaterial.uniforms.tNoise.value = this.pdNoiseTexture;
        this.pdMaterial.uniforms.resolution.value.set(this.width, this.height);
        this.pdMaterial.uniforms.lumaPhi.value = 10;
        this.pdMaterial.uniforms.depthPhi.value = 2;
        this.pdMaterial.uniforms.normalPhi.value = 3;
        this.pdMaterial.uniforms.radius.value = 8;

        this.depthRenderMaterial = new ShaderMaterial({
            defines: Object.assign({}, GTAODepthShader.defines),
            uniforms: UniformsUtils.clone(GTAODepthShader.uniforms),
            vertexShader: GTAODepthShader.vertexShader,
            fragmentShader: GTAODepthShader.fragmentShader,
            blending: NoBlending
        });
        this.depthRenderMaterial.uniforms.cameraNear.value = this.camera.near;
        this.depthRenderMaterial.uniforms.cameraFar.value = this.camera.far;

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

        this.blendMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(GTAOBlendShader.uniforms),
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

        if (parameters != null) {
            this.setGBuffer(parameters.depthTexture, parameters.normalTexture);
        }

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
        this.gtaoRenderTarget.dispose();
        this.pdRenderTarget.dispose();
        this.normalMaterial.dispose();
        this.pdMaterial.dispose();
        this.copyMaterial.dispose();
        this.depthRenderMaterial.dispose();
        this.fsQuad.dispose();
    }

    public function get gtaoMap():Texture {
        return this.pdRenderTarget.texture;
    }

    public function setGBuffer(?depthTexture:Texture, ?normalTexture:Texture) {
        if (depthTexture != null) {
            this.depthTexture = depthTexture;
            this.normalTexture = normalTexture;
            this._renderGBuffer = false;
        } else {
            this.depthTexture = new DepthTexture();
            this.depthTexture.format = DepthStencilFormat;
            this.depthTexture.type = UnsignedInt248Type;
            this.normalRenderTarget = new WebGLRenderTarget(this.width, this.height, {
                minFilter: NearestFilter,
                magFilter: NearestFilter,
                type: HalfFloatType,
                depthTexture: this.depthTexture
            });
            this.normalTexture = this.normalRenderTarget.texture;
            this._renderGBuffer = true;
        }

        const normalVectorType = this.normalTexture != null ? 1 : 0;
        const depthValueSource = this.depthTexture == this.normalTexture ? 'w' : 'x';

        this.gtaoMaterial.defines.NORMAL_VECTOR_TYPE = normalVectorType;
        this.gtaoMaterial.defines.DEPTH_SWIZZLING = depthValueSource;
        this.gtaoMaterial.uniforms.tNormal.value = this.normalTexture;
        this.gtaoMaterial.uniforms.tDepth.value = this.depthTexture;

        this.pdMaterial.defines.NORMAL_VECTOR_TYPE = normalVectorType;
        this.pdMaterial.defines.DEPTH_SWIZZLING = depthValueSource;
        this.pdMaterial.uniforms.tNormal.value = this.normalTexture;
        this.pdMaterial.uniforms.tDepth.value = this.depthTexture;

        this.depthRenderMaterial.uniforms.tDepth.value = this.normalRenderTarget.depthTexture;
    }

    public function setSceneClipBox(?box:Box3) {
        if (box != null) {
            this.gtaoMaterial.needsUpdate = this.gtaoMaterial.defines.SCENE_CLIP_BOX != 1;
            this.gtaoMaterial.defines.SCENE_CLIP_BOX = 1;
            this.gtaoMaterial.uniforms.sceneBoxMin.value.copy(box.min);
            this.gtaoMaterial.uniforms.sceneBoxMax.value.copy(box.max);
        } else {
            this.gtaoMaterial.needsUpdate = this.gtaoMaterial.defines.SCENE_CLIP_BOX == 0;
            this.gtaoMaterial.defines.SCENE_CLIP_BOX = 0;
        }
    }

    public function updateGtaoMaterial(parameters) {
        if (parameters.radius != null) {
            this.gtaoMaterial.uniforms.radius.value = parameters.radius;
        }

        if (parameters.distanceExponent != null) {
            this.gtaoMaterial.uniforms.distanceExponent.value = parameters.distanceExponent;
        }

        if (parameters.thickness != null) {
            this.gtaoMaterial.uniforms.thickness.value = parameters.thickness;
        }

        if (parameters.distanceFallOff != null) {
            this.gtaoMaterial.uniforms.distanceFallOff.value = parameters.distanceFallOff;
            this.gtaoMaterial.needsUpdate = true;
        }

        if (parameters.scale != null) {
            this.gtaoMaterial.uniforms.scale.value = parameters.scale;
        }

        if (parameters.samples != null && parameters.samples != this.gtaoMaterial.defines.SAMPLES) {
            this.gtaoMaterial.defines.SAMPLES = parameters.samples;
            this.gtaoMaterial.needsUpdate = true;
        }

        if (parameters.screenSpaceRadius != null && (parameters.screenSpaceRadius ? 1 : 0) != this.gtaoMaterial.defines.SCREEN_SPACE_RADIUS) {
            this.gtaoMaterial.defines.SCREEN_SPACE_RADIUS = parameters.screenSpaceRadius ? 1 : 0;
            this.gtaoMaterial.needsUpdate = true;
        }
    }

    public function updatePdMaterial(parameters) {
        let updateShader = false;

        if (parameters.lumaPhi != null) {
            this.pdMaterial.uniforms.lumaPhi.value = parameters.lumaPhi;
        }

        if (parameters.depthPhi != null) {
            this.pdMaterial.uniforms.depthPhi.value = parameters.depthPhi;
        }

        if (parameters.normalPhi != null) {
            this.pdMaterial.uniforms.normalPhi.value = parameters.normalPhi;
        }

        if (parameters.radius != null && parameters.radius != this.radius) {
            this.pdMaterial.uniforms.radius.value = parameters.radius;
        }

        if (parameters.radiusExponent != null && parameters.radiusExponent != this.pdRadiusExponent) {
            this.pdRadiusExponent = parameters.radiusExponent;
            updateShader = true;
        }

        if (parameters.rings != null && parameters.rings != this.pdRings) {
            this.pdRings = parameters.rings;
            updateShader = true;
        }

        if (parameters.samples != null && parameters.samples != this.pdSamples) {
            this.pdSamples = parameters.samples;
            updateShader = true;
        }

        if (updateShader) {
            this.pdMaterial.defines.SAMPLES = this.pdSamples;
            this.pdMaterial.defines.SAMPLE_VECTORS = generatePdSamplePointInitializer(this.pdSamples, this.pdRings, this.pdRadiusExponent);
            this.pdMaterial.needsUpdate = true;
        }
    }

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        // render normals and depth (honor only meshes, points and lines do not contribute to AO)

        if (this._renderGBuffer) {
            this.overrideVisibility();
            this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);
            this.restoreVisibility();
        }

        // render AO

        this.gtaoMaterial.uniforms.cameraNear.value = this.camera.near;
        this.gtaoMaterial.uniforms.cameraFar.value = this.camera.far;
        this.gtaoMaterial.uniforms.cameraProjectionMatrix.value.copy(this.camera.projectionMatrix);
        this.gtaoMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);
        this.gtaoMaterial.uniforms.cameraWorldMatrix.value.copy(this.camera.matrixWorld);
        this.renderPass(renderer, this.gtaoMaterial, this.gtaoRenderTarget, 0xffffff, 1.0);

        // render poisson denoise

        this.pdMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);
        this.renderPass(renderer, this.pdMaterial, this.pdRenderTarget, 0xffffff, 1.0);

        // output result to screen

        switch (this.output) {
            case GTAOPass.OUTPUT.Off:
                break;

            case GTAOPass.OUTPUT.Diffuse:
                this.copyMaterial.uniforms.tDiffuse.value = readBuffer.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
                break;

            case GTAOPass.OUTPUT.AO:
                this.copyMaterial.uniforms.tDiffuse.value = this.gtaoRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
                break;

            case GTAOPass.OUTPUT.Denoise:
                this.copyMaterial.uniforms.tDiffuse.value = this.pdRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
                break;

            case GTAOPass.OUTPUT.Depth:
                this.depthRenderMaterial.uniforms.cameraNear.value = this.camera.near;
                this.depthRenderMaterial.uniforms.cameraFar.value = this.camera.far;
                this.renderPass(renderer, this.depthRenderMaterial, this.renderToScreen ? null : writeBuffer);
                break;

            case GTAOPass.OUTPUT.Normal:
                this.copyMaterial.uniforms.tDiffuse.value = this.normalRenderTarget.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
                break;

            case GTAOPass.OUTPUT.Default:
                this.copyMaterial.uniforms.tDiffuse.value = readBuffer.texture;
                this.copyMaterial.blending = NoBlending;
                this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);

                this.blendMaterial.uniforms.intensity.value = this.blendIntensity;
                this.blendMaterial.uniforms.tDiffuse.value = this.pdRenderTarget.texture;
                this.renderPass(renderer, this.blendMaterial, this.renderToScreen ? null : writeBuffer);
                break;

            default:
                trace("THREE.GTAOPass: Unknown output type.");
        }
    }

    public function renderPass(renderer:Renderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, ?clearColor:Int, ?clearAlpha:Float) {
        // save original state
        renderer.getClearColor(this.originalClearColor);
        const originalClearAlpha = renderer.getClearAlpha();
        const originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);

        // setup pass state
        renderer.autoClear = false;
        if (clearColor != null && clearColor != null) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha != null ? clearAlpha : 0.0);
            renderer.clear();
        }

        this.fsQuad.material = passMaterial;
        this.fsQuad.render(renderer);

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(this.originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function renderOverride(renderer:Renderer, overrideMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, ?clearColor:Int, ?clearAlpha:Float) {
        renderer.getClearColor(this.originalClearColor);
        const originalClearAlpha = renderer.getClearAlpha();
        const originalAutoClear = renderer.autoClear;

        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        clearColor = overrideMaterial.clearColor != null ? overrideMaterial.clearColor : clearColor;
        clearAlpha = overrideMaterial.clearAlpha != null ? overrideMaterial.clearAlpha : clearAlpha;

        if (clearColor != null && clearColor != null) {
            renderer.setClearColor(clearColor);
            renderer.setClearAlpha(clearAlpha != null ? clearAlpha : 0.0);
            renderer.clear();
        }

        this.scene.overrideMaterial = overrideMaterial;
        renderer.render(this.scene, this.camera);
        this.scene.overrideMaterial = null;

        renderer.auto
        clear = originalAutoClear;
        renderer.setClearColor(this.originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function setSize(width:Int, height:Int) {
        this.width = width;
        this.height = height;

        this.gtaoRenderTarget.setSize(width, height);
        this.normalRenderTarget.setSize(width, height);
        this.pdRenderTarget.setSize(width, height);

        this.gtaoMaterial.uniforms.resolution.value.set(width, height);
        this.gtaoMaterial.uniforms.cameraProjectionMatrix.value.copy(this.camera.projectionMatrix);
        this.gtaoMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);

        this.pdMaterial.uniforms.resolution.value.set(width, height);
        this.pdMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);
    }

    public function overrideVisibility() {
        const scene = this.scene;
        const cache = this._visibilityCache;

        scene.traverse(function (object:DisplayObject) {
            cache.set(object, object.visible);

            if (object.isPoints || object.isLine) {
                object.visible = false;
            }
        });
    }

    public function restoreVisibility() {
        const scene = this.scene;
        const cache = this._visibilityCache;

        scene.traverse(function (object:DisplayObject) {
            const visible = cache.get(object);
            object.visible = visible;
        });

        cache.clear();
    }

    public function generateNoise(?size:Int = 64) {
        const simplex = new SimplexNoise();

        const arraySize = size * size * 4;
        const data = new Uint8Array(arraySize);

        for (let i = 0; i < size; i++) {
            for (let j = 0; j < size; j++) {
                const x = i;
                const y = j;

                data.set([(simplex.noise(x, y) * 0.5 + 0.5) * 255, (simplex.noise(x + size, y) * 0.5 + 0.5) * 255, (simplex.noise(x, y + size) * 0.5 + 0.5) * 255, (simplex.noise(x + size, y + size) * 0.5 + 0.5) * 255], (i * size + j) * 4);
            }
        }

        const noiseTexture = new DataTexture(data, size, size, RGBAFormat, UnsignedByteType);
        noiseTexture.wrapS = RepeatWrapping;
        noiseTexture.wrapT = RepeatWrapping;
        noiseTexture.needsUpdate = true;

        return noiseTexture;
    }
}

class GTAOPass {
    public static var OUTPUT:Map<String,Int> = {
        'Off': -1,
        'Default': 0,
        'Diffuse': 1,
        'Depth': 2,
        'Normal': 3,
        'AO': 4,
        'Denoise': 5,
    };
}

function generateMagicSquareNoise():Texture {
    // implementation...
}

function generatePdSamplePointInitializer(samples:Int, rings:Float, radiusExponent:Float):String {
    // implementation...
}