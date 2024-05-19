package three.js.examples.javascript.postprocessing;

import three.js.WebGLRenderTarget;
import three.js.HalfFloatType;
import three.js.Scene;
import three.js.Camera;
import three.js.Renderer;
import three.js.Texture;

class TAARenderPass extends SSAARenderPass {
    private var sampleLevel : Int;
    private var accumulate : Bool;
    private var accumulateIndex : Int;
    private var sampleRenderTarget : WebGLRenderTarget;
    private var holdRenderTarget : WebGLRenderTarget;
    private var copyUniforms : Dynamic;
    private var fsQuad : Dynamic;

    public function new(scene : Scene, camera : Camera, clearColor : Int, clearAlpha : Float) {
        super(scene, camera, clearColor, clearAlpha);
        sampleLevel = 0;
        accumulate = false;
        accumulateIndex = -1;
    }

    override public function render(renderer : Renderer, writeBuffer : WebGLRenderTarget, readBuffer : WebGLRenderTarget, deltaTime : Float) : Void {
        if (!accumulate) {
            super.render(renderer, writeBuffer, readBuffer, deltaTime);
            accumulateIndex = -1;
            return;
        }

        var jitterOffsets = _JitterVectors[5];

        if (sampleRenderTarget == null) {
            sampleRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, { type : HalfFloatType });
            sampleRenderTarget.texture.name = 'TAARenderPass.sample';
        }

        if (holdRenderTarget == null) {
            holdRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, { type : HalfFloatType });
            holdRenderTarget.texture.name = 'TAARenderPass.hold';
        }

        if (accumulateIndex == -1) {
            super.render(renderer, holdRenderTarget, readBuffer, deltaTime);
            accumulateIndex = 0;
        }

        var autoClear = renderer.autoClear;
        renderer.autoClear = false;

        var oldClearColor : Int = renderer.getClearColor();
        var oldClearAlpha : Float = renderer.getClearAlpha();

        var sampleWeight : Float = 1.0 / jitterOffsets.length;

        if (accumulateIndex >= 0 && accumulateIndex < jitterOffsets.length) {
            copyUniforms.opacity.value = sampleWeight;
            copyUniforms.tDiffuse.value = writeBuffer.texture;

            var numSamplesPerFrame : Int = Math.pow(2, sampleLevel);
            for (i in 0...numSamplesPerFrame) {
                var j : Int = accumulateIndex;
                var jitterOffset : Array<Float> = jitterOffsets[j];

                if (camera.setViewOffset != null) {
                    camera.setViewOffset(readBuffer.width, readBuffer.height, jitterOffset[0] * 0.0625, jitterOffset[1] * 0.0625, readBuffer.width, readBuffer.height);
                }

                renderer.setRenderTarget(writeBuffer);
                renderer.setClearColor(clearColor, clearAlpha);
                renderer.clear();
                renderer.render(scene, camera);

                renderer.setRenderTarget(sampleRenderTarget);
                if (accumulateIndex == 0) {
                    renderer.setClearColor(0x000000, 0.0);
                    renderer.clear();
                }

                fsQuad.render(renderer);

                accumulateIndex++;

                if (accumulateIndex >= jitterOffsets.length) break;
            }

            if (camera.clearViewOffset != null) camera.clearViewOffset();
        }

        renderer.setClearColor(clearColor, clearAlpha);
        var accumulationWeight : Float = accumulateIndex * sampleWeight;

        if (accumulationWeight > 0) {
            copyUniforms.opacity.value = 1.0;
            copyUniforms.tDiffuse.value = sampleRenderTarget.texture;
            renderer.setRenderTarget(writeBuffer);
            renderer.clear();
            fsQuad.render(renderer);
        }

        if (accumulationWeight < 1.0) {
            copyUniforms.opacity.value = 1.0 - accumulationWeight;
            copyUniforms.tDiffuse.value = holdRenderTarget.texture;
            renderer.setRenderTarget(writeBuffer);
            fsQuad.render(renderer);
        }

        renderer.autoClear = autoClear;
        renderer.setClearColor(oldClearColor, oldClearAlpha);
    }

    override public function dispose() : Void {
        super.dispose();
        if (holdRenderTarget != null) holdRenderTarget.dispose();
    }
}

private var _JitterVectors : Array<Array<Array<Float>>> = [
    [
        [0, 0]
    ],
    [
        [4, 4], [-4, -4]
    ],
    [
        [-2, -6], [6, -2], [-6, 2], [2, 6]
    ],
    [
        [1, -3], [-1, 3], [5, 1], [-3, -5],
        [-5, 5], [-7, -1], [3, 7], [7, -7]
    ],
    [
        [1, 1], [-1, -3], [-3, 2], [4, -1],
        [-5, -2], [2, 5], [5, 3], [3, -5],
        [-2, 6], [0, -7], [-4, -6], [-6, 4],
        [-8, 0], [7, -4], [6, 7], [-7, -8]
    ],
    [
        [-4, -7], [-7, -5], [-3, -5], [-5, -4],
        [-1, -4], [-2, -2], [-6, -1], [-4, 0],
        [-7, 1], [-1, 2], [-6, 3], [-3, 3],
        [-7, 6], [-3, 6], [-5, 7], [-1, 7],
        [5, -7], [1, -6], [6, -5], [4, -4],
        [2, -3], [7, -2], [1, -1], [4, -1],
        [2, 1], [6, 2], [0, 4], [4, 4],
        [2, 5], [7, 5], [5, 6], [3, 7]
    ]
];