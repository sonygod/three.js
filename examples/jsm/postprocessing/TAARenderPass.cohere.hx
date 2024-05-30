import js.three.WebGLRenderTarget;
import js.three.HalfFloatType;

import SSAARenderPass from './SSAARenderPass.hx';

/**
 * Temporal Anti-Aliasing Render Pass
 *
 * When there is no motion in the scene, the TAA render pass accumulates jittered camera samples across frames to create a high quality anti-aliased result.
 *
 * References:
 *
 * TODO: Add support for motion vector passes so that accumulation of samples across frames can occur on dynamic scenes.
 *
 */
class TAARenderPass extends SSAARenderPass {
    public var sampleLevel:Int;
    public var accumulate:Bool;
    public var accumulateIndex:Int;
    public var sampleRenderTarget:WebGLRenderTarget;
    public var holdRenderTarget:WebGLRenderTarget;

    public function new(scene:Dynamic, camera:Dynamic, clearColor:Dynamic, clearAlpha:Float) {
        super(scene, camera, clearColor, clearAlpha);
        this.sampleLevel = 0;
        this.accumulate = false;
        this.accumulateIndex = -1;
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float) {
        if (!this.accumulate) {
            super.render(renderer, writeBuffer, readBuffer, deltaTime);
            this.accumulateIndex = -1;
            return;
        }

        var jitterOffsets = _JitterVectors[5];

        if (this.sampleRenderTarget == null) {
            this.sampleRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, { type: HalfFloatType });
            this.sampleRenderTarget.texture.name = 'TAARenderPass.sample';
        }

        if (this.holdRenderTarget == null) {
            this.holdRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, { type: HalfFloatType });
            this.holdRenderTarget.texture.name = 'TAARenderPass.hold';
        }

        if (this.accumulateIndex == -1) {
            super.render(renderer, this.holdRenderTarget, readBuffer, deltaTime);
            this.accumulateIndex = 0;
        }

        var autoClear = renderer.autoClear;
        renderer.autoClear = false;

        var _oldClearColor = renderer.getClearColor();
        var oldClearAlpha = renderer.getClearAlpha();

        var sampleWeight = 1.0 / jitterOffsets.length;

        if (this.accumulateIndex >= 0 && this.accumulateIndex < jitterOffsets.length) {
            this.copyUniforms['opacity'].value = sampleWeight;
            this.copyUniforms['tDiffuse'].value = writeBuffer.texture;

            // render the scene multiple times, each slightly jitter offset from the last and accumulate the results.
            var numSamplesPerFrame = Math.pow(2, this.sampleLevel);
            var i:Int;
            for (i = 0; i < numSamplesPerFrame; i++) {
                var j = this.accumulateIndex;
                var jitterOffset = jitterOffsets[j];

                if (this.camera.setViewOffset != null) {
                    this.camera.setViewOffset(readBuffer.width, readBuffer.height,
                        jitterOffset[0] * 0.0625, jitterOffset[1] * 0.0625, // 0.0625 = 1 / 16
                        readBuffer.width, readBuffer.height);
                }

                renderer.setRenderTarget(writeBuffer);
                renderer.setClearColor(this.clearColor, this.clearAlpha);
                renderer.clear();
                renderer.render(this.scene, this.camera);

                renderer.setRenderTarget(this.sampleRenderTarget);
                if (this.accumulateIndex == 0) {
                    renderer.setClearColor(0x000000, 0.0);
                    renderer.clear();
                }

                this.fsQuad.render(renderer);

                this.accumulateIndex++;

                if (this.accumulateIndex >= jitterOffsets.length) {
                    break;
                }
            }

            if (this.camera.clearViewOffset != null) {
                this.camera.clearViewOffset();
            }
        }

        renderer.setClearColor(this.clearColor, this.clearAlpha);
        var accumulationWeight = this.accumulateIndex * sampleWeight;

        if (accumulationWeight > 0) {
            this.copyUniforms['opacity'].value = 1.0;
            this.copyUniforms['tDiffuse'].value = this.sampleRenderTarget.texture;
            renderer.setRenderTarget(writeBuffer);
            renderer.clear();
            this.fsQuad.render(renderer);
        }

        if (accumulationWeight < 1.0) {
            this.copyUniforms['opacity'].value = 1.0 - accumulationWeight;
            this.copyUniforms['tDiffuse'].value = this.holdRenderTarget.texture;
            renderer.setRenderTarget(writeBuffer);
            this.fsQuad.render(renderer);
        }

        renderer.autoClear = autoClear;
        renderer.setClearColor(_oldClearColor, oldClearAlpha);
    }

    public function dispose() {
        super.dispose();
        if (this.holdRenderTarget != null) {
            this.holdRenderTarget.dispose();
        }
    }
}

var _JitterVectors = [
    [[0, 0]],
    [[4, 4], [-4, -4]],
    [[-2, -6], [6, -2], [-6, 2], [2, 6]],
    [[1, -3], [-1, 3], [5, 1], [-3, -5], [-5, 5], [-7, -1], [3, 7], [7, -7]],
    [[1, 1], [-1, -3], [-3, 2], [4, -1], [-5, -2], [2, 5], [5, 3], [3, -5], [-2, 6], [0, -7], [-4, -6], [-6, 4], [-8, 0], [7, -4], [6, 7], [-7, -8]],
    [[-4, -7], [-7, -5], [-3, -5], [-5, -4], [-1, -4], [-2, -2], [-6, -1], [-4, 0], [-7, 1], [-1, 2], [-6, 3], [-3, 3], [-7, 6], [-3, 6], [-5, 7], [-1, 7], [5, -7], [1, -6], [6, -5], [4, -4], [2, -3], [7, -2], [1, -1], [4, -1], [2, 1], [6, 2], [0, 4], [4, 4], [2, 5], [7, 5], [5, 6], [3, 7]]
];

class TAARenderPassDefinition {
    public static function __init__() {
        js.three.TAARenderPass = TAARenderPass;
    }
}

TAARenderPassDefinition.__init__();