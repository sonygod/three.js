import js.three.WebGLRenderTarget;
import js.three.Color;
import js.three.MeshDepthMaterial;
import js.three.RGBADepthPacking;
import js.three.NoBlending;
import js.three.HalfFloatType;
import js.three.NearestFilter;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.Pass;
import js.three.FullScreenQuad;
import js.three.BokehShader;

class BokehPass extends Pass {
    var scene:Dynamic;
    var camera:Dynamic;
    var renderTargetDepth:WebGLRenderTarget;
    var materialDepth:MeshDepthMaterial;
    var materialBokeh:ShaderMaterial;
    var fsQuad:FullScreenQuad;
    var uniforms:Dynamic;
    var _oldClearColor:Color;

    public function new(scene:Dynamic, camera:Dynamic, params:Dynamic) {
        super();
        this.scene = scene;
        this.camera = camera;
        var focus = params.focus != null ? params.focus : 1.0;
        var aperture = params.aperture != null ? params.aperture : 0.025;
        var maxblur = params.maxblur != null ? params.maxblur : 1.0;
        renderTargetDepth = new WebGLRenderTarget(1, 1, {
            minFilter: NearestFilter.new(),
            magFilter: NearestFilter.new(),
            type: HalfFloatType.new()
        });
        renderTargetDepth.texture.name = 'BokehPass.depth';
        materialDepth = new MeshDepthMaterial();
        materialDepth.depthPacking = RGBADepthPacking.new();
        materialDepth.blending = NoBlending.new();
        var bokehShader = BokehShader.new();
        var bokehUniforms = UniformsUtils.clone(bokehShader.uniforms);
        bokehUniforms.tDepth.value = renderTargetDepth.texture;
        bokehUniforms.focus.value = focus;
        bokehUniforms.aspect.value = camera.aspect;
        bokehUniforms.aperture.value = aperture;
        bokehUniforms.maxblur.value = maxblur;
        bokehUniforms.nearClip.value = camera.near;
        bokehUniforms.farClip.value = camera.far;
        materialBokeh = new ShaderMaterial({
            defines: js.threemonkeybits.Object.assign({}, bokehShader.defines),
            uniforms: bokehUniforms,
            vertexShader: bokehShader.vertexShader,
            fragmentShader: bokehShader.fragmentShader
        });
        uniforms = bokehUniforms;
        fsQuad = new FullScreenQuad(materialBokeh);
        _oldClearColor = new Color();
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
        scene.overrideMaterial = materialDepth;
        renderer.getClearColor(_oldClearColor);
        var oldClearAlpha = renderer.getClearAlpha();
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;
        renderer.setClearColor(0xffffff);
        renderer.setClearAlpha(1.0);
        renderer.setRenderTarget(renderTargetDepth);
        renderer.clear();
        renderer.render(scene, camera);
        uniforms.tColor.value = readBuffer.texture;
        uniforms.nearClip.value = camera.near;
        uniforms.farClip.value = camera.far;
        if (this.renderToScreen) {
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
        materialBokeh.uniforms.aspect.value = width / height;
        renderTargetDepth.setSize(width, height);
    }

    public function dispose() {
        renderTargetDepth.dispose();
        materialDepth.dispose();
        materialBokeh.dispose();
        fsQuad.dispose();
    }
}