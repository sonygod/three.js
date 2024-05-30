package three.renderers.shaders;

#if !macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class ShaderChunk {
    public static inline var logdepthbuf_pars_fragment:String = 
        #if defined( USE_LOGDEPTHBUF )

            "uniform float logDepthBufFC;\n" +
            "varying float vFragDepth;\n" +
            "varying float vIsPerspective;\n"

        #end;
}