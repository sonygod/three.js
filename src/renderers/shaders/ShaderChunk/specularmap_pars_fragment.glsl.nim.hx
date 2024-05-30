package three.js.src.renderers.shaders.ShaderChunk;

class specularmap_pars_fragment {
    static var code = new StringBuf()
        .add("#ifdef USE_SPECULARMAP\n")
        .add("	uniform sampler2D specularMap;\n")
        .add("#endif\n");
}