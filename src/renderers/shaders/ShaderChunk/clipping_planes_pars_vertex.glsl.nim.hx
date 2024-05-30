package three.src.renderers.shaders.ShaderChunk;

class clipping_planes_pars_vertex {
    static public var code(macro:haxe.macro.Expr):String {
        #if (NUM_CLIPPING_PLANES > 0)
            return "
                varying vec3 vClipPosition;
            ";
        #else
            return "";
        #end
    }
}