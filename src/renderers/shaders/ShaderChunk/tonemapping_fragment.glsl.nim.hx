package three.renderers.shaders.ShaderChunk;

class TonemappingFragment {
    public static inline function tonemapping_fragment() {
        #if defined(TONE_MAPPING)
            gl_FragColor.rgb = toneMapping(gl_FragColor.rgb);
        #end
        return "";
    }
}