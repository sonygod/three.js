package three.renderers.shaders.ShaderChunk;

class LogDepthBufParsVertex {
    static public var code(inline:Bool):String {
        #if useLogDepthBuf
            return "
                varying float vFragDepth;
                varying float vIsPerspective;
            ";
        #else
            return "";
        #end
    }
}