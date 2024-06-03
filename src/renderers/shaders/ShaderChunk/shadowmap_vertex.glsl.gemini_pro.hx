import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Macro;
import haxe.macro.Position;
import haxe.macro.Type;

class GlslMacro extends Macro {
  public function onMacro(context:Context, expr:Expr):Expr {
    var code = "#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )\n\n\t// Offsetting the position used for querying occlusion along the world normal can be used to reduce shadow acne.\n\tvec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );\n\tvec4 shadowWorldPosition;\n\n#endif\n\n#if defined( USE_SHADOWMAP )\n\n\t#if NUM_DIR_LIGHT_SHADOWS > 0\n\n\t\t#pragma unroll_loop_start\n\t\tfor ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {\n\n\t\t\tshadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );\n\t\t\tvDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;\n\n\t\t}\n\t\t#pragma unroll_loop_end\n\n\t#endif\n\n\t#if NUM_POINT_LIGHT_SHADOWS > 0\n\n\t\t#pragma unroll_loop_start\n\t\tfor ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {\n\n\t\t\tshadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );\n\t\t\tvPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;\n\n\t\t}\n\t\t#pragma unroll_loop_end\n\n\t#endif\n\n\t/*\n\t#if NUM_RECT_AREA_LIGHTS > 0\n\n\t\t// TODO (abelnation): update vAreaShadowCoord with area light info\n\n\t#endif\n\t*/\n\n#endif\n\n// spot lights can be evaluated without active shadow mapping (when SpotLight.map is used)\n\n#if NUM_SPOT_LIGHT_COORDS > 0\n\n\t#pragma unroll_loop_start\n\tfor ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {\n\n\t\tshadowWorldPosition = worldPosition;\n\t\t#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )\n\t\t\tshadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;\n\t\t#endif\n\t\tvSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;\n\n\t}\n\t#pragma unroll_loop_end\n\n#endif\n\n";
    return macro.parseString(code, Position.fromExpr(expr));
  }
}

@:macro(GlslMacro)
class Glsl {
  public function new() {}
}