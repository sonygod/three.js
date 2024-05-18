import three.math.SimplexNoise;
import three.core.Color;
import three.textures.DataTexture;
import three.textures.DepthTexture;
import three.textures.Texture;
import three.renderers.webgl.WebGLRenderTarget;
import three.materials.ShaderMaterial;
import three.materials.UniformsUtils;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix4;
import three.core.Object3D;
import three.core.Scene;
import three.core.Camera;
import three.renderers.FullScreenQuad;
import three.renderers.WebGLRenderer;
import three.renderers.Renderer;
import three.math.UniformsLib;
import three.postprocessing.Pass;

class GTAOPass extends Pass {

    public var width:Int;
    public var height:Int;
    public var clear:Bool;
    public var camera:Camera;
    public var scene:Scene;
    public var output:Int;
    public var _renderGBuffer:Bool;
    public var _visibilityCache:Map<Object3D,Bool>;
    public var blendIntensity:Float;

    public var pdRings:Float;
    public var pdRadiusExponent:Float;
    public var pdSamples:Int;

    public var gtaoNoiseTexture:Texture;
    public var pdNoiseTexture:Texture;

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

    public function new(scene:Scene, camera:Camera, width:Int = -1, height:Int = -1, parameters:Dynamic = null, aoParameters:Dynamic = null, pdParameters:Dynamic = null) {
        super();

        this.width = ( width !== -1 ) ? width : 512;
        this.height = ( height !== -1 ) ? height : 512;
        this.clear = true;
        this.camera = camera;
        this.scene = scene;
        this.output = 0;
        this._renderGBuffer = true;
        this._visibilityCache = new Map<Object3D,Bool>();
        this.blendIntensity = 1.;

        this.pdRings = 2.;
        this.pdRadiusExponent = 2.;
        this.pdSamples = 16;

        this.gtaoNoiseTexture = this.generateNoise();
        this.pdNoiseTexture = this.generateNoise();

        this.gtaoRenderTarget = new WebGLRenderTarget(this.width, this.height, {type:halfFloatType});
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
        this.depthRenderMaterial.uniforms.tDepth.value = this.normalRenderTarget.depthTexture;

        this.copyMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(CopyShader.uniforms),
            vertexShader: CopyShader.vertexShader,
            fragmentShader: CopyShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
        });

        this.blendMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(GTAOBlendShader.uniforms),
            vertexShader: GTAOBlendShader.vertexShader,
            fragmentShader: GTAOBlendShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
        });

        this.fsQuad = new FullScreenQuad(null);

        this.originalClearColor = new Color();

        this.setGBuffer(parameters ? parameters.depthTexture : null, parameters ? parameters.normalTexture : null);

        if (aoParameters !== null) {
            this.updateGtaoMaterial(aoParameters);
        }

        if (pdParameters !== null) {
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

    public function get gtaoMap():Texture {
        return this.pdRenderTarget.texture;
    }

    public function setGBuffer(depthTexture:Texture, normalTexture:Texture) {
        if (depthTexture !== null) {
            this.depthTexture = depthTexture;
            this.normalTexture = normalTexture;
            this._renderGBuffer = false;
        } else {
            this.depthTexture = new DepthTexture();
            this.depthTexture.format = DepthStencilFormat;
            this.depthTexture.type = UnsignedInt248Type;
            this.normalRenderTarget = new WebGLRenderTarget(this.width, this.height, {
                minFilter:NearestFilter,
                magFilter:NearestFilter,
                type:halfFloatType,
                depthTexture:this.depthTexture
            });
            this.normalTexture = this.normalRenderTarget.texture;
            this._renderGBuffer = true;
        }

        const normalVectorType = (this.normalTexture !== null) ? 1 : 0;
        const depthValueSource = (this.depthTexture === this.normalTexture) ? 'x' : 'x';

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

    public function setSceneClipBox(box:Vector3) {
        if (box !== null) {
            this.gtaoMaterial.needsUpdate = this.gtaoMaterial.defines.SCENE_CLIP_BOX !== 1;
            this.gtaoMaterial.defines.SCENE_CLIP_BOX = 1;
            this.gtaoMaterial.uniforms.sceneBoxMin.value.copy(box);
            this.gtaoMaterial.uniforms.sceneBoxMax.value.copy(box);
        } else {
            this.gtaoMaterial.needsUpdate = this.gtaoMaterial.defines.SCENE_CLIP_BOX === 0;
            this.gtaoMaterial.defines.SCENE_CLIP_BOX = 0;
        }
    }

    public function updateGtaoMaterial(parameters) {
        if (parameters.radius !== undefined) {
            this.gtaoMaterial.uniforms.radius.value = parameters.radius;
        }

        if (parameters.distanceExponent !== undefined) {
            this.gtaoMaterial.uniforms.distanceExponent.value = parameters.distanceExponent;
        }

        if (parameters.thickness !== undefined) {
            this.gtaoMaterial.uniforms.thickness.value = parameters.thickness;
        }

        if (parameters.distanceFallOff !== undefined) {
            this.gtaoMaterial.uniforms.distanceFallOff.value = parameters.distanceFallOff;
            this.gtaoMaterial.needsUpdate = true;
        }

        if (parameters.scale !== undefined) {
            this.gtaoMaterial.uniforms.scale.value = parameters.scale;
        }

        if (parameters.samples !== undefined && parameters.samples !== this.gtaoMaterial.defines.SAMPLES) {
            this.gtaoMaterial.defines.SAMPLES = parameters.samples;
            this.gtaoMaterial.needsUpdate = true;
        }

        if (parameters.screenSpaceRadius !== undefined && (parameters.screenSpaceRadius ? 1 : 0) !== this.gtaoMaterial.defines.SCREEN_SPACE_RADIUS) {
            this.gtaoMaterial.defines.SCREEN_SPACE_RADIUS = parameters.screenSpaceRadius ? 1 : 0;
            this.gtaoMaterial.needsUpdate = true;
        }
    }

    public function updatePdMaterial(parameters) {
        let updateShader = false;

        if (parameters.lumaPhi !== undefined) {
            this.pdMaterial.uniforms.lumaPhi.value = parameters.lumaPhi;
        }

        if (parameters.depthPhi !== undefined) {
            this.pdMaterial.uniforms.depthPhi.value = parameters.depthPhi;
        }

        if (parameters.normalPhi !== undefined) {
            this.pdMaterial.uniforms.normalPhi.value = parameters.normalPhi;
        }

        if (parameters.radius !== undefined && parameters.radius !== this.pdMaterial.uniforms.radius.value) {
            this.pdMaterial.uniforms.radius.value = parameters.radius;
        }

        if (parameters.radiusExponent !== undefined && parameters.radiusExponent !== this.pdRadiusExponent) {
            this.pdRadiusExponent = parameters.radiusExponent;
            updateShader = true;
        }

        if (parameters.rings !== undefined && parameters.rings !== this.pdRings) {
            this.pdRings = parameters.rings;
            updateShader = true;
        }

        if (parameters.samples !== undefined && parameters.samples !== this.pdSamples) {
            this.pdSamples = parameters.samples;
            updateShader = true;
        }

        if (updateShader) {
            this.pdMaterial.defines.SAMPLES = this.pdSamples;
            this.pdMaterial.defines.SAMPLE_VECTORS = generatePdSamplePointInitializer(this.pdSamples, this.pdRings, this.pdRadiusExponent);
            this.pdMaterial.needsUpdate = true;
        }
    }

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {
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
                console.warn("THREE.GTAOPass: Unknown output type.");

        }
    }

    // ... rest of the code ...

}

// ... rest of the code ...