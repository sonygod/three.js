import three.AdditiveBlending;
import three.Color;
import three.HalfFloatType;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import postprocessing.Pass;
import postprocessing.FullScreenQuad;
import shaders.CopyShader;

class SSAARenderPass extends Pass {
    private var scene:three.Scene;
    private var camera:three.Camera;
    private var sampleLevel:Int = 4;
    private var unbiased:Bool = true;
    private var clearColor:Int;
    private var clearAlpha:Float;
    private var _oldClearColor:Color;
    private var copyUniforms:Map<String, Dynamic>;
    private var copyMaterial:ShaderMaterial;
    private var fsQuad:FullScreenQuad;
    private var sampleRenderTarget:WebGLRenderTarget;

    public function new(scene:three.Scene, camera:three.Camera, clearColor:Int, clearAlpha:Float) {
        super();
        this.scene = scene;
        this.camera = camera;
        this.clearColor = if (clearColor != null) clearColor else 0x000000;
        this.clearAlpha = if (clearAlpha != null) clearAlpha else 0;
        this._oldClearColor = new Color();

        var copyShader = CopyShader;
        this.copyUniforms = UniformsUtils.clone(copyShader.uniforms);

        this.copyMaterial = new ShaderMaterial({
            uniforms: this.copyUniforms,
            vertexShader: copyShader.vertexShader,
            fragmentShader: copyShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
            premultipliedAlpha: true,
            blending: AdditiveBlending
        });

        this.fsQuad = new FullScreenQuad(this.copyMaterial);
    }

    public function dispose():Void {
        if (this.sampleRenderTarget != null) {
            this.sampleRenderTarget.dispose();
            this.sampleRenderTarget = null;
        }

        this.copyMaterial.dispose();
        this.fsQuad.dispose();
    }

    public function setSize(width:Int, height:Int):Void {
        if (this.sampleRenderTarget != null) this.sampleRenderTarget.setSize(width, height);
    }

    public function render(renderer:three.WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget):Void {
        if (this.sampleRenderTarget == null) {
            this.sampleRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, { type: HalfFloatType });
            this.sampleRenderTarget.texture.name = 'SSAARenderPass.sample';
        }

        var jitterOffsets = _JitterVectors[Math.min(Math.max(0, this.sampleLevel), 5)];
        var autoClear = renderer.autoClear;
        renderer.autoClear = false;

        renderer.getClearColor(this._oldClearColor);
        var oldClearAlpha = renderer.getClearAlpha();

        var baseSampleWeight = 1.0 / jitterOffsets.length;
        var roundingRange = 1 / 32;
        this.copyUniforms['tDiffuse'].value = this.sampleRenderTarget.texture;

        var viewOffset = {
            fullWidth: readBuffer.width,
            fullHeight: readBuffer.height,
            offsetX: 0,
            offsetY: 0,
            width: readBuffer.width,
            height: readBuffer.height
        };

        var originalViewOffset = {
            enabled: this.camera.view.enabled,
            fullWidth: this.camera.view.fullWidth,
            fullHeight: this.camera.view.fullHeight,
            offsetX: this.camera.view.offsetX,
            offsetY: this.camera.view.offsetY,
            width: this.camera.view.width,
            height: this.camera.view.height
        };

        for (i in 0...jitterOffsets.length) {
            var jitterOffset = jitterOffsets[i];

            if (this.camera.setViewOffset != null) {
                this.camera.setViewOffset(
                    viewOffset.fullWidth, viewOffset.fullHeight,
                    viewOffset.offsetX + jitterOffset[0] * 0.0625, viewOffset.offsetY + jitterOffset[1] * 0.0625,
                    viewOffset.width, viewOffset.height
                );
            }

            var sampleWeight = baseSampleWeight;

            if (this.unbiased) {
                var uniformCenteredDistribution = -0.5 + (i + 0.5) / jitterOffsets.length;
                sampleWeight += roundingRange * uniformCenteredDistribution;
            }

            this.copyUniforms['opacity'].value = sampleWeight;
            renderer.setClearColor(this.clearColor, this.clearAlpha);
            renderer.setRenderTarget(this.sampleRenderTarget);
            renderer.clear();
            renderer.render(this.scene, this.camera);

            renderer.setRenderTarget(if (this.renderToScreen) null else writeBuffer);

            if (i == 0) {
                renderer.setClearColor(0x000000, 0.0);
                renderer.clear();
            }

            this.fsQuad.render(renderer);
        }

        if (this.camera.setViewOffset != null && originalViewOffset.enabled) {
            this.camera.setViewOffset(
                originalViewOffset.fullWidth, originalViewOffset.fullHeight,
                originalViewOffset.offsetX, originalViewOffset.offsetY,
                originalViewOffset.width, originalViewOffset.height
            );
        } else if (this.camera.clearViewOffset != null) {
            this.camera.clearViewOffset();
        }

        renderer.autoClear = autoClear;
        renderer.setClearColor(this._oldClearColor, oldClearAlpha);
    }
}

var _JitterVectors = [
    [[0, 0]],
    [[4, 4], [-4, -4]],
    [[-2, -6], [6, -2], [-6, 2], [2, 6]],
    [[1, -3], [-1, 3], [5, 1], [-3, -5], [-5, 5], [-7, -1], [3, 7], [7, -7]],
    [[1, 1], [-1, -3], [-3, 2], [4, -1], [-5, -2], [2, 5], [5, 3], [3, -5], [-2, 6], [0, -7], [-4, -6], [-6, 4], [-8, 0], [7, -4], [6, 7], [-7, -8]]
];