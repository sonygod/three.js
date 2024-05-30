package three.renderers.shaders.ShaderChunk;

class aomap_pars_fragment {
    static public var code(inline:Bools) {
        #if (use_aomap)
            var code = new StringBuf();
            code.add("uniform sampler2D aoMap;\n");
            code.add("uniform float aoMapIntensity;\n");
            return code.toString();
        #else
            return "";
        #end
    }
}