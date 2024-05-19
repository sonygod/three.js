package three.js.examples.jsm.postprocessing;

import three.Color;
import three.HalfFloatType;
import three.MeshDepthMaterial;
import three.NearestFilter;
import three.NoBlending;
import three.RGBADepthPacking;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import Pass;
import FullScreenQuad;
import BokehShader;

class BokehPass extends Pass {
    public var scene:Scene;
    public var camera:Camera;
    public var renderTargetDepth:WebGLRenderTarget;
    public var materialDepth:MeshDepthMaterial;
    public var materialBokeh:ShaderMaterial;
    public var fsQuad:FullScreenQuad;
    public var uniforms:Dynamic;
    public var _oldClearColor:Color;

    public function new(scene:Scene, camera:Camera, params:Dynamic = null) {
        super();
        this.scene = scene;
        this.camera = camera;

        var focus:Float = params != null && params.focus != null ? params.focus : 1.0;
        var aperture:Float = params != null && params.aperture != null ? params.aperture : 0.025;
        var maxblur:Float = params != null && params.maxblur != null ? params.maxblur : 1.0;

        // render targets
        this.renderTargetDepth = new WebGLRenderTarget(1, 1, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType
        });
        this.renderTargetDepth.texture.name = 'BokehPass.depth';

        // depth material
        this.materialDepth = new MeshDepthMaterial();
        this.materialDepth.depthPacking = RGBADepthPacking;
        this.materialDepth.blending = NoBlending;

        // bokeh material
        var bokehShader:BokehShader = new BokehShader();
        var bokehUniforms:Dynamic = UniformsUtils.clone(bokehShader.uniforms);

        bokehUniforms['tDepth'].value = this.renderTargetDepth.texture;

        bokehUniforms['focus'].value = focus;
        bokehUniforms['aspect'].value = camera.aspect;
        bokehUniforms['aperture'].value = aperture;
        bokehUniforms['maxblur'].value = maxblur;
        bokehUniforms['nearClip'].value = camera.near;
        bokehUniforms['farClip'].value = camera.far;

        this.materialBokeh = new ShaderMaterial({
            defines: Object.assign({}, bokehShader.defines),
            uniforms: bokehUniforms,
            vertexShader: bokehShader.vertexShader,
            fragmentShader: bokehShader.fragmentShader
        });

        this.uniforms = bokehUniforms;

        this.fsQuad = new FullScreenQuad(this.materialBokeh);

        this._oldClearColor = new Color();
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float = 0, maskActive:Bool = false) {
        // Render depth into texture
        this.scene.overrideMaterial = this.materialDepth;

        var oldClearColor:Color = renderer.getClearColor(this._oldClearColor);
        var oldClearAlpha:Float = renderer.getClearAlpha();
        var oldAutoClear:Bool = renderer.autoClear;
        renderer.autoClear = false;

        renderer.setClearColor(0xffffff);
        renderer.setClearAlpha(1.0);
        renderer.setRenderTarget(this.renderTargetDepth);
        renderer.clear();
        renderer.render(this.scene, this.camera);

        // Render bokeh composite
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
        renderer.setClearColor(oldClearColor);
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