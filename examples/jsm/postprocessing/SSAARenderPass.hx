package three.js.examples.jsm.postprocessing;

import three.js.AdditiveBlending;
import three.js.Color;
import three.js.HalfFloatType;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;
import three.js.WebGLRenderTarget;
import three.js.Passes.Pass;
import three.js.Passes.FullScreenQuad;
import three.js.shaders.CopyShader;

class SSAARenderPass extends Pass {
    public var scene:Scene;
    public var camera:Camera;
    public var sampleLevel:Int = 4; // specified as n, where the number of samples is 2^n, so sampleLevel = 4, is 2^4 samples, 16.
    public var unbiased:Bool = true;
    public var clearColor:Int;
    public var clearAlpha:Float;
    public var _oldClearColor:Color;
    public var copyUniforms:Uniforms;
    public var copyMaterial:ShaderMaterial;
    public var fsQuad:FullScreenQuad;
    public var sampleRenderTarget:WebGLRenderTarget;

    public function new(scene:Scene, camera:Camera, clearColor:Int = 0x000000, clearAlpha:Float = 0.0) {
        super();
        this.scene = scene;
        this.camera = camera;
        this.clearColor = clearColor;
        this.clearAlpha = clearAlpha;
        this._oldClearColor = new Color();

        var copyShader:CopyShader = new CopyShader();
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

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        if (this.sampleRenderTarget == null) {
            this.sampleRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, { type: HalfFloatType });
            this.sampleRenderTarget.texture.name = 'SSAARenderPass.sample';
        }

        var jitterOffsets:Array<Array<Int>> = _JitterVectors[Math.max(0, Math.min(this.sampleLevel, 5))];
        var autoClear:Bool = renderer.autoClear;
        renderer.autoClear = false;

        renderer.getClearColor(this._oldClearColor);
        var oldClearAlpha:Float = renderer.getClearAlpha();

        var baseSampleWeight:Float = 1.0 / jitterOffsets.length;
        var roundingRange:Float = 1 / 32;
        this.copyUniforms['tDiffuse'].value = this.sampleRenderTarget.texture;

        var viewOffset:Object = {
            fullWidth: readBuffer.width,
            fullHeight: readBuffer.height,
            offsetX: 0,
            offsetY: 0,
            width: readBuffer.width,
            height: readBuffer.height
        };

        var originalViewOffset:Object = this.camera.view.clone();
        if (originalViewOffset.enabled) Object.assign(viewOffset, originalViewOffset);

        for (i in 0...jitterOffsets.length) {
            var jitterOffset:Array<Int> = jitterOffsets[i];

            if (this.camera.setViewOffset != null) {
                this.camera.setViewOffset(
                    viewOffset.fullWidth, viewOffset.fullHeight,
                    viewOffset.offsetX + jitterOffset[0] * 0.0625, viewOffset.offsetY + jitterOffset[1] * 0.0625, // 0.0625 = 1 / 16
                    viewOffset.width, viewOffset.height
                );
            }

            var sampleWeight:Float = baseSampleWeight;

            if (this.unbiased) {
                // the theory is that equal weights for each sample lead to an accumulation of rounding errors.
                // The following equation varies the sampleWeight per sample so that it is uniformly distributed
                // across a range of values whose rounding errors cancel each other out.

                var uniformCenteredDistribution:Float = (-0.5 + (i + 0.5) / jitterOffsets.length);
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

// These jitter vectors are specified in integers because it is easier.
// I am assuming a [-8,8) integer grid, but it needs to be mapped onto [-0.5,0.5)
// before being used, thus these integers need to be scaled by 1/16.
const _JitterVectors:Array<Array.Array<Int>> = [
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