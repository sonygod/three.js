import three.js.three.Constants;
import three.js.three.WebGLRenderTarget;
import three.js.three.ShaderMaterial;
import three.js.three.MeshBasicMaterial;
import three.js.three.MeshNormalMaterial;
import three.js.three.DepthTexture;
import three.js.three.UnsignedShortType;
import three.js.three.HalfFloatType;
import three.js.three.NearestFilter;
import three.js.three.NoBlending;
import three.js.three.SrcAlphaFactor;
import three.js.three.OneMinusSrcAlphaFactor;
import three.js.three.AddEquation;
import three.js.three.Color;

class SSRPass extends Pass {
    public var renderer:Renderer;
    public var scene:Scene;
    public var camera:Camera;
    public var groundReflector:GroundReflector;
    public var selects:Array<Dynamic>;
    public var bouncing:Bool;
    public var blur:Bool;
    public var distanceAttenuation:Bool;
    public var fresnel:Bool;
    public var infiniteThick:Bool;
    public var output:Int;
    public var beautyRenderTarget:WebGLRenderTarget;
    public var prevRenderTarget:WebGLRenderTarget;
    public var normalRenderTarget:WebGLRenderTarget;
    public var metalnessRenderTarget:WebGLRenderTarget;
    public var ssrRenderTarget:WebGLRenderTarget;
    public var blurRenderTarget:WebGLRenderTarget;
    public var blurRenderTarget2:WebGLRenderTarget;
    public var ssrMaterial:ShaderMaterial;
    public var normalMaterial:MeshNormalMaterial;
    public var metalnessOnMaterial:MeshBasicMaterial;
    public var metalnessOffMaterial:MeshBasicMaterial;
    public var blurMaterial:ShaderMaterial;
    public var blurMaterial2:ShaderMaterial;
    public var depthRenderMaterial:ShaderMaterial;
    public var copyMaterial:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(renderer:Renderer, scene:Scene, camera:Camera, width:Int, height:Int, selects:Array<Dynamic>, bouncing:Bool = false, groundReflector:GroundReflector = null) {
        super();
        this.renderer = renderer;
        this.scene = scene;
        this.camera = camera;
        this.groundReflector = groundReflector;
        this.selects = selects;
        this.bouncing = bouncing;
        this.blur = true;
        this.distanceAttenuation = true;
        this.fresnel = true;
        this.infiniteThick = true;
        this.output = 0;

        this.beautyRenderTarget = new WebGLRenderTarget(width, height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType,
            depthTexture: new DepthTexture(UnsignedShortType, NearestFilter, NearestFilter),
            depthBuffer: true
        });

        this.prevRenderTarget = new WebGLRenderTarget(width, height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter
        });

        this.normalRenderTarget = new WebGLRenderTarget(width, height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType
        });

        this.metalnessRenderTarget = new WebGLRenderTarget(width, height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType
        });

        this.ssrRenderTarget = new WebGLRenderTarget(width, height, {
            minFilter: NearestFilter,
            magFilter: NearestFilter
        });

        this.blurRenderTarget = ssrRenderTarget.clone();
        this.blurRenderTarget2 = ssrRenderTarget.clone();

        this.ssrMaterial = new ShaderMaterial({
            defines: {
                MAX_STEP: Math.sqrt(width * width + height * height)
            },
            uniforms: {
                tDiffuse: { value: beautyRenderTarget.texture },
                tNormal: { value: normalRenderTarget.texture },
                tMetalness: { value: metalnessRenderTarget.texture },
                tDepth: { value: beautyRenderTarget.depthTexture },
                cameraNear: { value: camera.near },
                cameraFar: { value: camera.far },
                thickness: { value: 0.1 },
                resolution: { value: new Vector2(width, height) },
                cameraProjectionMatrix: { value: camera.projectionMatrix },
                cameraInverseProjectionMatrix: { value: camera.projectionMatrixInverse }
            },
            vertexShader: SSRShader.vertexShader,
            fragmentShader: SSRShader.fragmentShader,
            blending: NoBlending
        });

        this.normalMaterial = new MeshNormalMaterial();
        this.normalMaterial.blending = NoBlending;

        this.metalnessOnMaterial = new MeshBasicMaterial({ color: 0xffffff });
        this.metalnessOffMaterial = new MeshBasicMaterial({ color: 0x000000 });

        this.blurMaterial = new ShaderMaterial({
            defines: SSRBlurShader.defines,
            uniforms: SSRBlurShader.uniforms,
            vertexShader: SSRBlurShader.vertexShader,
            fragmentShader: SSRBlurShader.fragmentShader
        });
        this.blurMaterial.uniforms.tDiffuse.value = ssrRenderTarget.texture;
        this.blurMaterial.uniforms.resolution.value = new Vector2(width, height);

        this.blurMaterial2 = new ShaderMaterial({
            defines: SSRBlurShader.defines,
            uniforms: SSRBlurShader.uniforms,
            vertexShader: SSRBlurShader.vertexShader,
            fragmentShader: SSRBlurShader.fragmentShader
        });
        this.blurMaterial2.uniforms.tDiffuse.value = blurRenderTarget.texture;
        this.blurMaterial2.uniforms.resolution.value = new Vector2(width, height);

        this.depthRenderMaterial = new ShaderMaterial({
            defines: SSRDepthShader.defines,
            uniforms: SSRDepthShader.uniforms,
            vertexShader: SSRDepthShader.vertexShader,
            fragmentShader: SSRDepthShader.fragmentShader,
            blending: NoBlending
        });
        this.depthRenderMaterial.uniforms.tDepth.value = beautyRenderTarget.depthTexture;
        this.depthRenderMaterial.uniforms.cameraNear.value = camera.near;
        this.depthRenderMaterial.uniforms.cameraFar.value = camera.far;

        this.copyMaterial = new ShaderMaterial({
            uniforms: CopyShader.uniforms,
            vertexShader: CopyShader.vertexShader,
            fragmentShader: CopyShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
            blending: new BlendEquation(AddEquation, SrcAlphaFactor, OneMinusSrcAlphaFactor)
        });

        this.fsQuad = new FullScreenQuad(null);
    }

    public function dispose() {
        beautyRenderTarget.dispose();
        prevRenderTarget.dispose();
        normalRenderTarget.dispose();
        metalnessRenderTarget.dispose();
        ssrRenderTarget.dispose();
        blurRenderTarget.dispose();
        blurRenderTarget2.dispose();

        normalMaterial.dispose();
        metalnessOnMaterial.dispose();
        metalnessOffMaterial.dispose();
        blurMaterial.dispose();
        blurMaterial2.dispose();
        copyMaterial.dispose();
        depthRenderMaterial.dispose();

        fsQuad.dispose();
    }

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {
        // render beauty and depth
        renderer.setRenderTarget(beautyRenderTarget);
        renderer.clear();
        if (groundReflector != null) {
            groundReflector.visible = false;
            groundReflector.doRender(renderer, scene, camera);
            groundReflector.visible = true;
        }
        renderer.render(scene, camera);
        if (groundReflector != null) groundReflector.visible = false;

        // render normals
        renderOverride(renderer, normalMaterial, normalRenderTarget);

        // render metalness
        if (selective) {
            renderMetalness(renderer, metalnessOnMaterial, metalnessRenderTarget);
        }

        // render SSR
        ssrMaterial.uniforms.opacity.value = 1.0;
        ssrMaterial.uniforms.maxDistance.value = 10.0;
        ssrMaterial.uniforms.thickness.value = 0.1;
        renderPass(renderer, ssrMaterial, ssrRenderTarget);

        // render blur
        if (blur) {
            renderPass(renderer, blurMaterial, blurRenderTarget);
            renderPass(renderer, blurMaterial2, blurRenderTarget2);
        }

        // output result to screen
        switch (output) {
            case 0: // Default
                if (bouncing) {
                    copyMaterial.uniforms.tDiffuse.value = beautyRenderTarget.texture;
                    copyMaterial.blending = NoBlending;
                    renderPass(renderer, copyMaterial, prevRenderTarget);

                    if (blur) {
                        copyMaterial.uniforms.tDiffuse.value = blurRenderTarget2.texture;
                    } else {
                        copyMaterial.uniforms.tDiffuse.value = ssrRenderTarget.texture;
                    }
                    copyMaterial.blending = NormalBlending;
                    renderPass(renderer, copyMaterial, prevRenderTarget);

                    copyMaterial.uniforms.tDiffuse.value = prevRenderTarget.texture;
                    copyMaterial.blending = NoBlending;
                    renderPass(renderer, copyMaterial, null);
                } else {
                    copyMaterial.uniforms.tDiffuse.value = beautyRenderTarget.texture;
                    copyMaterial.blending = NoBlending;
                    renderPass(renderer, copyMaterial, null);

                    if (blur) {
                        copyMaterial.uniforms.tDiffuse.value = blurRenderTarget2.texture;
                    } else {
                        copyMaterial.uniforms.tDiffuse.value = ssrRenderTarget.texture;
                    }
                    copyMaterial.blending = NormalBlending;
                    renderPass(renderer, copyMaterial, null);
                }
                break;
            case 1: // SSR
                if (blur) {
                    copyMaterial.uniforms.tDiffuse.value = blurRenderTarget2.texture;
                } else {
                    copyMaterial.uniforms.tDiffuse.value = ssrRenderTarget.texture;
                }
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, null);
                break;
            case 3: // Beauty
                copyMaterial.uniforms.tDiffuse.value = beautyRenderTarget.texture;
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, null);
                break;
            case 4: // Depth
                renderPass(renderer, depthRenderMaterial, null);
                break;
            case 5: // Normal
                copyMaterial.uniforms.tDiffuse.value = normalRenderTarget.texture;
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, null);
                break;
            case 7: // Metalness
                copyMaterial.uniforms.tDiffuse.value = metalnessRenderTarget.texture;
                copyMaterial.blending = NoBlending;
                renderPass(renderer, copyMaterial, null);
                break;
            default:
                console.warn("THREE.SSRPass: Unknown output type.");
        }
    }

    public function renderPass(renderer:Renderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget) {
        // save original state
        var originalClearColor = renderer.getClearColor();
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        // setup pass state
        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        fsQuad.material = passMaterial;
        fsQuad.render(renderer);

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function renderOverride(renderer:Renderer, overrideMaterial:Material, renderTarget:WebGLRenderTarget) {
        // save original state
        var originalClearColor = renderer.getClearColor();
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        // setup pass state
        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        scene.overrideMaterial = overrideMaterial;
        renderer.render(scene, camera);
        scene.overrideMaterial = null;

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function renderMetalness(renderer:Renderer, overrideMaterial:Material, renderTarget:WebGLRenderTarget) {
        // save original state
        var originalClearColor = renderer.getClearColor();
        var originalClearAlpha = renderer.getClearAlpha();
        var originalAutoClear = renderer.autoClear;

        // setup pass state
        renderer.setRenderTarget(renderTarget);
        renderer.autoClear = false;

        scene.traverseVisible(function(child) {
            child._SSRPassBackupMaterial = child.material;
            if (selects.includes(child)) {
                child.material = metalnessOnMaterial;
            } else {
                child.material = metalnessOffMaterial;
            }
        });
        renderer.render(scene, camera);
        scene.traverseVisible(function(child) {
            child.material = child._SSRPassBackupMaterial;
        });

        // restore original state
        renderer.autoClear = originalAutoClear;
        renderer.setClearColor(originalClearColor);
        renderer.setClearAlpha(originalClearAlpha);
    }

    public function setSize(width:Int, height:Int) {
        this.width = width;
        this.height = height;

        ssrMaterial.defines.MAX_STEP = Math.sqrt(width * width + height * height);
        ssrMaterial.needsUpdate = true;

        beautyRenderTarget.setSize(width, height);
        prevRenderTarget.setSize(width, height);
        ssrRenderTarget.setSize(width, height);
        normalRenderTarget.setSize(width, height);
        metalnessRenderTarget.setSize(width, height);
        blurRenderTarget.setSize(width, height);
        blurRenderTarget2.setSize(width, height);

        ssrMaterial.uniforms.resolution.value.set(width, height);
        blurMaterial.uniforms.resolution.value.set(width, height);
        blurMaterial2.uniforms.resolution.value.set(width, height);
    }
}