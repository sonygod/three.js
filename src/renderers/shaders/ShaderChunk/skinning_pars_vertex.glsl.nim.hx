package three.renderers.shaders.ShaderChunk;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import heaps.glsl.GlslExpr;
import heaps.glsl.GlslMacro;
import heaps.glsl.GlslType;

@:build(macro:ShaderChunk_skinning_pars_vertex.build)
class ShaderChunk_skinning_pars_vertex {
    public static function build(ctx:Context):Array<Field> {
        var expr:Expr = macro {
            var size:Int = Context.getLocal(0).getGLSLExpr("textureSize(boneTexture, 0).x");
            var j:Int = Context.getLocal(1).getGLSLExpr("int(i) * 4");
            var x:Int = j % size;
            var y:Int = j / size;
            var v1:GlslExpr = Context.getLocal(2).getGLSLExpr("texelFetch(boneTexture, ivec2(x, y), 0)");
            var v2:GlslExpr = Context.getLocal(3).getGLSLExpr("texelFetch(boneTexture, ivec2(x + 1, y), 0)");
            var v3:GlslExpr = Context.getLocal(4).getGLSLExpr("texelFetch(boneTexture, ivec2(x + 2, y), 0)");
            var v4:GlslExpr = Context.getLocal(5).getGLSLExpr("texelFetch(boneTexture, ivec2(x + 3, y), 0)");

            return GlslExpr.Mat4(v1, v2, v3, v4);
        };

        return [
            {
                name: "getBoneMatrix",
                meta: [GlslMacro(expr, [GlslType.Float, GlslType.Int, GlslType.Int, GlslType.Int, GlslType.Int, GlslType.Int])],
                access: [APrivate, AStatic]
            }
        ];
    }
}