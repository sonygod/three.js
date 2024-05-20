import js.Lib;

class ShaderChunk {
    public static var normal_pars_vertex(glsl:String):String {
        return Lib.unsafe(glsl);
    }
}