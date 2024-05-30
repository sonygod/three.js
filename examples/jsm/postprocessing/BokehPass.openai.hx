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
import three.pass.FullScreenQuad;
import three.pass.Pass;
import three.shaders.BokehShader;

class BokehPass extends Pass {

    public var scene:Scene;
    public var camera:Camera;

    private var renderTargetDepth:WebGLRenderTarget;
    private var materialDepth:MeshDepthMaterial;
    private var materialBokeh:ShaderMaterial;
    private var fsQuad:FullScreenQuad;
    private var _oldClearColor:Color;

    public function new(scene:Scene, camera:Camera, params:{focus:Float, aperture:Float, maxblur:Float}) {
        super();

        this.scene = scene;
        this.camera = camera;

        var focus:Float = params.focus != null ? params.focus : 1.0;
        var aperture:Float = params.aperture != null ? params.aperture : 0.025;
        var maxblur:Float = params.maxblur != null ? params.maxblur : 1.0;

        // render targets
        renderTargetDepth = new WebGLRenderTarget(1, 1, {
            minFilter: NearestFilter,
            magFilter: NearestFilter,
            type: HalfFloatType
        });
        renderTargetDepth.texture.name = 'BokehPass.depth';

        // depth material
        materialDepth = new MeshDepthMaterial();
        materialDepth.depthPacking = RGBADepthPacking;
        materialDepth.blending = NoBlending;

        // bokeh material
        var bokehShader:BokehShader = new BokehShader();
        var bokehUniforms:Dynamic = UniformsUtils.clone(bokehShader.uniforms);

        bokehUniforms['tDepth'].value = renderTargetDepth.texture;
        bokehUniforms['focus'].value = focus;
        bokehUniforms['aspect'].value = camera.aspect;
        bokehUniforms['aperture'].value = aperture;
        bokehUniforms['maxblur'].value = maxblur;
        bokehUniforms['nearClip'].value = camera.near;
        bokehUniforms['farClip'].value = camera.far;

        materialBokeh = new ShaderMaterial({
            defines: bokehShader.defines,
            uniforms: bokehUniforms,
            vertexShader: bokehShader.vertexShader,
            fragmentShader: bokehShader.fragmentShader
        });

        fsQuad = new FullScreenQuad(materialBokeh);

        _oldClearColor = new Color();
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        // Render depth into texture
        scene.overrideMaterial = materialDepth;

        _oldClearColor.copy(renderer.getClearColor());
        var oldClearAlpha = renderer.getClearAlpha();
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        renderer.setClearColor(new Color(0xffffff));
        renderer.setClearAlpha(1.0);
        renderer.setRenderTarget(renderTargetDepth);
        renderer.clear();
        renderer.render(scene, camera);

        // Render bokeh composite
        materialBokeh.uniforms['tColor'].value = readBuffer.texture;
        materialBokeh.uniforms['nearClip'].value = camera.near;
        materialBokeh.uniforms['farClip'].value = camera.far;

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            renderer.clear();
            fsQuad.render(renderer);
        }

        scene.overrideMaterial = null;
        renderer.setClearColor(_oldClearColor);
        renderer.setClearAlpha(oldClearAlpha);
        renderer.autoClear = oldAutoClear;
    }

    public function setSize(width:Int, height:Int) {
        materialBokeh.uniforms['aspect'].value = width / height;
        renderTargetDepth.setSize(width, height);
    }

    public function dispose() {
        renderTargetDepth.dispose();
        materialDepth.dispose();
        materialBokeh.dispose();
        fsQuad.dispose();
    }
}