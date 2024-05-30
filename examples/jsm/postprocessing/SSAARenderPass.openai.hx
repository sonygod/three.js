package three.js.examples.jsm.postprocessing;

import three.js_ADDITIVE_BLENDING;
import three.js_Color;
import three.js_HalfFloatType;
import three.js_ShaderMaterial;
import three.js_UniformsUtils;
import three.js_WebGLRenderTarget;
import three.js_Pass;
import three.js_FullScreenQuad;
import three.js_CopyShader;

class SSAARenderPass extends Pass {
    public var scene:Scene;
    public var camera:Camera;
    public var sampleLevel:Int = 4;
    public var unbiased:Bool = true;
    public var clearColor:Int = 0x000000;
    public var clearAlpha:Float = 0.0;
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
        _oldClearColor = new Color();
        var copyShader:CopyShader = new CopyShader();
        copyUniforms = UniformsUtils.clone(copyShader.uniforms);
        copyMaterial = new ShaderMaterial({
            uniforms: copyUniforms,
            vertexShader: copyShader.vertexShader,
            fragmentShader: copyShader.fragmentShader,
            transparent: true,
            depthTest: false,
            depthWrite: false,
            premultipliedAlpha: true,
            blending: ADDITIVE_BLENDING
        });
        fsQuad = new FullScreenQuad(copyMaterial);
    }

    public function dispose() {
        if (sampleRenderTarget != null) {
            sampleRenderTarget.dispose();
            sampleRenderTarget = null;
        }
        copyMaterial.dispose();
        fsQuad.dispose();
    }

    public function setSize(width:Int, height:Int) {
        if (sampleRenderTarget != null) {
            sampleRenderTarget.setSize(width, height);
        }
    }

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        if (sampleRenderTarget == null) {
            sampleRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, {
                type: HalfFloatType
            });
            sampleRenderTarget.texture.name = 'SSAARenderPass.sample';
        }

        var jitterOffsets:Array<Array<Int>> = _JitterVectors[Math.min(sampleLevel, 5)];
        var autoClear:Bool = renderer.autoClear;
        renderer.autoClear = false;

        renderer.getClearColor(_oldClearColor);
        var oldClearAlpha:Float = renderer.getClearAlpha();

        var baseSampleWeight:Float = 1.0 / jitterOffsets.length;
        var roundingRange:Float = 1 / 32;
        copyUniforms.get('tDiffuse').value = sampleRenderTarget.texture;

        var viewOffset:Dynamic = {
            fullWidth: readBuffer.width,
            fullHeight: readBuffer.height,
            offsetX: 0,
            offsetY: 0,
            width: readBuffer.width,
            height: readBuffer.height
        };

        var originalViewOffset:Dynamic = {};
        if (camera.view != null && camera.view.enabled) {
            for (field in Type.getInstanceFields(camera.view)) {
                Reflect.setField(originalViewOffset, field, Reflect.field(camera.view, field));
            }
        }

        for (i in 0...jitterOffsets.length) {
            var jitterOffset:Array<Int> = jitterOffsets[i];
            if (camera.setViewOffset != null) {
                camera.setViewOffset(
                    viewOffset.fullWidth, viewOffset.fullHeight,
                    viewOffset.offsetX + jitterOffset[0] * 0.0625, viewOffset.offsetY + jitterOffset[1] * 0.0625,
                    viewOffset.width, viewOffset.height
                );
            }

            var sampleWeight:Float = baseSampleWeight;
            if (unbiased) {
                var uniformCenteredDistribution:Float = (-0.5 + (i + 0.5) / jitterOffsets.length);
                sampleWeight += roundingRange * uniformCenteredDistribution;
            }

            copyUniforms.get('opacity').value = sampleWeight;
            renderer.setClearColor(clearColor, clearAlpha);
            renderer.setRenderTarget(sampleRenderTarget);
            renderer.clear();
            renderer.render(scene, camera);

            renderer.setRenderTarget(writeBuffer);

            if (i == 0) {
                renderer.setClearColor(0x000000, 0.0);
                renderer.clear();
            }

            fsQuad.render(renderer);
        }

        if (camera.setViewOffset != null && originalViewOffset != null) {
            camera.setViewOffset(
                originalViewOffset.fullWidth, originalViewOffset.fullHeight,
                originalViewOffset.offsetX, originalViewOffset.offsetY,
                originalViewOffset.width, originalViewOffset.height
            );
        } else if (camera.clearViewOffset != null) {
            camera.clearViewOffset();
        }

        renderer.autoClear = autoClear;
        renderer.setClearColor(_oldClearColor, oldClearAlpha);
    }
}

// These jitter vectors are specified in integers because it is easier.
// I am assuming a [-8,8) integer grid, but it needs to be mapped onto [-0.5,0.5)
// before being used, thus these integers need to be scaled by 1/16.
const _JitterVectors:Array<Array<Array<Int>>> = [
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