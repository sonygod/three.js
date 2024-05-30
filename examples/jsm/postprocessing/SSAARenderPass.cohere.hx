import js.three.AdditiveBlending;
import js.three.Color;
import js.three.HalfFloatType;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.WebGLRenderTarget;

import js.three.Pass;
import js.three.FullScreenQuad;
import js.three.CopyShader;

class SSAARenderPass extends Pass {
    var scene:Dynamic;
    var camera:Dynamic;
    var clearColor:Int;
    var clearAlpha:Float;
    var sampleLevel:Int;
    var unbiased:Bool;
    var _oldClearColor:Color;
    var copyShader:CopyShader;
    var copyUniforms:Dynamic;
    var copyMaterial:ShaderMaterial;
    var fsQuad:FullScreenQuad;
    var sampleRenderTarget:WebGLRenderTarget;

    public function new(scene:Dynamic, camera:Dynamic, ?clearColor:Int, ?clearAlpha:Float) {
        super();
        this.scene = scene;
        this.camera = camera;
        this.clearColor = (clearColor != null) ? clearColor : 0x000000;
        this.clearAlpha = (clearAlpha != null) ? clearAlpha : 0.0;
        this._oldClearColor = new Color();
        this.copyShader = new CopyShader();
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

    public function dispose() {
        if (this.sampleRenderTarget != null) {
            this.sampleRenderTarget.dispose();
            this.sampleRenderTarget = null;
        }
        this.copyMaterial.dispose();
        this.fsQuad.dispose();
    }

    public function setSize(width:Int, height:Int) {
        if (this.sampleRenderTarget != null) {
            this.sampleRenderTarget.setSize(width, height);
        }
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
        if (this.sampleRenderTarget == null) {
            this.sampleRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, { type: HalfFloatType });
            this.sampleRenderTarget.texture.name = 'SSAARenderPass.sample';
        }

        var jitterOffsets = _JitterVectors[Math.max(0, Math.min(this.sampleLevel, 5))];

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

        var originalViewOffset = camera.view;

        if (originalViewOffset.enabled) {
            viewOffset = originalViewOffset;
        }

        for (i in 0...jitterOffsets.length) {
            var jitterOffset = jitterOffsets[i];

            if (camera.setViewOffset != null) {
                camera.setViewOffset(
                    viewOffset.fullWidth, viewOffset.fullHeight,
                    viewOffset.offsetX + jitterOffset[0] * 0.0625, viewOffset.offsetY + jitterOffset[1] * 0.0625,
                    viewOffset.width, viewOffset.height
                );
            }

            var sampleWeight = baseSampleWeight;

            if (this.unbiased) {
                var uniformCenteredDistribution = (-0.5 + (i + 0.5) / jitterOffsets.length);
                sampleWeight += roundingRange * uniformCenteredDistribution;
            }

            this.copyUniforms['opacity'].value = sampleWeight;
            renderer.setClearColor(this.clearColor, this.clearAlpha);
            renderer.setRenderTarget(this.sampleRenderTarget);
            renderer.clear();
            renderer.render(this.scene, this.camera);

            renderer.setRenderTarget(this.renderToScreen ? null : writeBuffer);

            if (i == 0) {
                renderer.setClearColor(0x000000, 0.0);
                renderer.clear();
            }

            this.fsQuad.render(renderer);
        }

        if (camera.setViewOffset != null && originalViewOffset.enabled) {
            camera.setViewOffset(
                originalViewOffset.fullWidth, originalViewOffset.fullHeight,
                originalViewOffset.offsetX, originalViewOffset.offsetY,
                originalViewOffset.width, originalViewOffset.height
            );
        } else if (camera.clearViewOffset != null) {
            camera.clearViewOffset();
        }

        renderer.autoClear = autoClear;
        renderer.setClearColor(this._oldClearColor, oldClearAlpha);
    }

    static var _JitterVectors = [
        [[0, 0]],
        [[4, 4], [-4, -4]],
        [[-2, -6], [6, -2], [-6, 2], [2, 6]],
        [[1, -3], [-1, 3], [5, 1], [-3, -5], [-5, 5], [-7, -1], [3, 7], [7, -7]],
        [[1, 1], [-1, -3], [-3, 2], [4, -1], [-5, -2], [2, 5], [5, 3], [3, -5], [-2, 6], [0, -7], [-4, -6], [-6, 4], [-8, 0], [7, -4], [6, 7], [-7, -8]]
    ];
}