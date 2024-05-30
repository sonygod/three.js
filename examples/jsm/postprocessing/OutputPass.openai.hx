package three.js.examples.jsm.postprocessing;

import three.ColorManagement;
import three.RawShaderMaterial;
import three.UniformsUtils;
import three.LinearToneMapping;
import three.ReinhardToneMapping;
import three.CineonToneMapping;
import three.AgXToneMapping;
import three.ACESFilmicToneMapping;
import three.NeutralToneMapping;
import three.SRGBTransfer;
import Pass;
import FullScreenQuad;
import OutputShader;

class OutputPass extends Pass {

    public function new() {
        super();

        var shader:OutputShader = OutputShader.getInstance();

        uniforms = UniformsUtils.clone(shader.uniforms);

        material = new RawShaderMaterial({
            name: shader.name,
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        fsQuad = new FullScreenQuad(material);

        _outputColorSpace = null;
        _toneMapping = null;
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Float, maskActive:Bool */ ) {
        uniforms['tDiffuse'].value = readBuffer.texture;
        uniforms['toneMappingExposure'].value = renderer.toneMappingExposure;

        if (_outputColorSpace != renderer.outputColorSpace || _toneMapping != renderer.toneMapping) {
            _outputColorSpace = renderer.outputColorSpace;
            _toneMapping = renderer.toneMapping;

            material.defines = {};

            if (ColorManagement.getTransfer(_outputColorSpace) == SRGBTransfer) material.defines.SRGB_TRANSFER = '';

            if (_toneMapping == LinearToneMapping) material.defines.LINEAR_TONE_MAPPING = '';
            else if (_toneMapping == ReinhardToneMapping) material.defines.REINHARD_TONE_MAPPING = '';
            else if (_toneMapping == CineonToneMapping) material.defines.CINEON_TONE_MAPPING = '';
            else if (_toneMapping == ACESFilmicToneMapping) material.defines.ACES_FILMIC_TONE_MAPPING = '';
            else if (_toneMapping == AgXToneMapping) material.defines.AGX_TONE_MAPPING = '';
            else if (_toneMapping == NeutralToneMapping) material.defines.NEUTRAL_TONE_MAPPING = '';

            material.needsUpdate = true;
        }

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
            fsQuad.render(renderer);
        }
    }

    public function dispose() {
        material.dispose();
        fsQuad.dispose();
    }
}