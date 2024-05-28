package three.renderers.shaders.ShaderChunk;

import haxe.macro.Expr;

class ColorVertexShader {
    public static var shader:String = {

        #if defined(USE_COLOR_ALPHA)
            "vColor = vec4(1.0);";

        #elseif defined(USE_COLOR) || defined(USE_INSTANCING_COLOR) || defined(USE_BATCHING_COLOR)
            "vColor = vec3(1.0);";

        #end

        #if defined(USE_COLOR)
            "vColor *= color;";

        #end

        #if defined(USE_INSTANCING_COLOR)
            "vColor.xyz *= instanceColor.xyz;";

        #end

        #if defined(USE_BATCHING_COLOR)
            "vec3 batchingColor = getBatchingColor(batchId);";
            "vColor.xyz *= batchingColor.xyz;";

        #end
    };
}