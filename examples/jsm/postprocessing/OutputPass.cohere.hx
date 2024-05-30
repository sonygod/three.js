import js.three.ColorManagement;
import js.three.Material;
import js.three.Pass;
import js.three.RawShaderMaterial;
import js.three.Shader;
import js.three.UniformsUtils;

import js.three.renderers.WebGLRenderer;

import js.three.textures.Texture;

class OutputPass extends Pass {
    public var uniforms:Map<String, dynamic>;
    public var material:RawShaderMaterial;
    public var fsQuad:FullScreenQuad;
    private var _outputColorSpace:Int;
    private var _toneMapping:Int;

    public function new() {
        super();

        var shader = cast OutputShader;

        uniforms = UniformsUtils.clone(shader.uniforms);
        material = new RawShaderMaterial({
            name: shader.name,
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        fsQuad = new FullScreenQuad(material);
    }

    public function render(renderer:WebGLRenderer, writeBuffer:Texture, readBuffer:Texture) {
        uniforms.set('tDiffuse', readBuffer);
        uniforms.set('toneMappingExposure', renderer.toneMappingExposure);

        if (_outputColorSpace != renderer.outputColorSpace || _toneMapping != renderer.toneMapping) {
            _outputColorSpace = renderer.outputColorSpace;
            _toneMapping = renderer.toneMapping;

            material.defines = new Map();

            if (ColorManagement.getTransfer(_outputColorSpace) == SRGBTransfer) {
                material.defines.set('SRGB_TRANSFER', '');
            }

            if (_toneMapping == LinearToneMapping) {
                material.defines.set('LINEAR_TONE_MAPPING', '');
            } else if (_toneMapping == ReinhardToneMapping) {
                material.defines.set('REINHARD_TONE_MAPPING', '');
            } else if (_toneMapping == CineonToneMapping) {
                material.defines.set('CINEON_TONE_MAPPING', '');
            } else if (_toneMapping == ACESFilmicToneMapping) {
                material.defines.set('ACES_FILMIC_TONE_MAPPING', '');
            } else if (_toneMapping == AgXToneMapping) {
                material.defines.set('AGX_TONE_MAPPING', '');
            } else if (_toneMapping == NeutralToneMapping) {
                material.defines.set('NEUTRAL_TONE_MAPPING', '');
            }

            material.needsUpdate = true;
        }

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) {
                renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
            }
            fsQuad.render(renderer);
        }
    }

    public function dispose() {
        material.dispose();
        fsQuad.dispose();
    }
}