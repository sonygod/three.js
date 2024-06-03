import three.Color;
import three.HalfFloatType;
import three.MeshDepthMaterial;
import three.NearestFilter;
import three.NoBlending;
import three.RGBADepthPacking;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;

import PostProcessing.Pass;
import PostProcessing.FullScreenQuad;
import Shaders.BokehShader;

class BokehPass extends Pass {
    public var scene:Scene;
    public var camera:Camera;
    public var renderTargetDepth:WebGLRenderTarget;
    public var materialDepth:MeshDepthMaterial;
    public var materialBokeh:ShaderMaterial;
    public var uniforms:Dynamic;
    public var fsQuad:FullScreenQuad;
    private var _oldClearColor:Color;

    public function new(scene:Scene, camera:Camera, params:Dynamic) {
        super();

        this.scene = scene;
        this.camera = camera;

        var focus = (params.hasOwnProperty('focus')) ? params.focus : 1.0;
        var aperture = (params.hasOwnProperty('aperture')) ? params.aperture : 0.025;
        var maxblur = (params.hasOwnProperty('maxblur')) ? params.maxblur : 1.0;

        this.renderTargetDepth = new WebGLRenderTarget(1, 1, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType
        });

        this.renderTargetDepth.texture.name = 'BokehPass.depth';

        this.materialDepth = new MeshDepthMaterial();
        this.materialDepth.depthPacking = RGBADepthPacking;
        this.materialDepth.blending = NoBlending;

        var bokehShader = BokehShader;
        var bokehUniforms = UniformsUtils.clone(bokehShader.uniforms);

        bokehUniforms['tDepth'].value = this.renderTargetDepth.texture;
        bokehUniforms['focus'].value = focus;
        bokehUniforms['aspect'].value = camera.aspect;
        bokehUniforms['aperture'].value = aperture;
        bokehUniforms['maxblur'].value = maxblur;
        bokehUniforms['nearClip'].value = camera.near;
        bokehUniforms['farClip'].value = camera.far;

        this.materialBokeh = new ShaderMaterial({
            defines: js.Boot.cast<Dynamic>(bokehShader.defines),
            uniforms: bokehUniforms,
            vertexShader: bokehShader.vertexShader,
            fragmentShader: bokehShader.fragmentShader
        });

        this.uniforms = bokehUniforms;

        this.fsQuad = new FullScreenQuad(this.materialBokeh);

        this._oldClearColor = new Color();
    }

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        this.scene.overrideMaterial = this.materialDepth;

        renderer.getClearColor(this._oldClearColor);
        var oldClearAlpha = renderer.getClearAlpha();
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        renderer.setClearColor(0xffffff);
        renderer.setClearAlpha(1.0);
        renderer.setRenderTarget(this.renderTargetDepth);
        renderer.clear();
        renderer.render(this.scene, this.camera);

        this.uniforms['tColor'].value = readBuffer.texture;
        this.uniforms['nearClip'].value = this.camera.near;
        this.uniforms['farClip'].value = this.camera.far;

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            renderer.clear();
            this.fsQuad.render(renderer);
        }

        this.scene.overrideMaterial = null;
        renderer.setClearColor(this._oldClearColor);
        renderer.setClearAlpha(oldClearAlpha);
        renderer.autoClear = oldAutoClear;
    }

    public function setSize(width:Int, height:Int) {
        this.materialBokeh.uniforms['aspect'].value = width / height;
        this.renderTargetDepth.setSize(width, height);
    }

    public function dispose() {
        this.renderTargetDepth.dispose();
        this.materialDepth.dispose();
        this.materialBokeh.dispose();
        this.fsQuad.dispose();
    }
}