package three.js.src.renderers.shaders.ShaderChunk;

@:build(macro.Library.jsFile("three.js/src/renderers/shaders/ShaderChunk/normalmap_pars_fragment.glsl.js"))
extern class Normalmap_pars_fragment {

  @:jsStatic
  public static var USE_NORMALMAP: String;

  @:jsStatic
  public static var normalMap: String;

  @:jsStatic
  public static var normalScale: String;

  @:jsStatic
  public static var USE_NORMALMAP_OBJECTSPACE: String;

  @:jsStatic
  public static var normalMatrix: String;

  @:jsStatic
  public static var USE_TANGENT: String;

  @:jsStatic
  public static var USE_NORMALMAP_TANGENTSPACE: String;

  @:jsStatic
  public static var USE_CLEARCOAT_NORMALMAP: String;

  @:jsStatic
  public static var USE_ANISOTROPY: String;

  @:jsStatic
  public static function getTangentFrame(eye_pos: String, surf_norm: String, uv: String): String {
    #if ! defined ( USE_TANGENT ) && ( defined ( USE_NORMALMAP_TANGENTSPACE ) || defined ( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY ) )
      return "
      mat3 getTangentFrame( vec3 eye_pos, vec3 surf_norm, vec2 uv ) {
        vec3 q0 = dFdx( eye_pos.xyz );
        vec3 q1 = dFdy( eye_pos.xyz );
        vec2 st0 = dFdx( uv.st );
        vec2 st1 = dFdy( uv.st );
        vec3 N = surf_norm; // normalized
        vec3 q1perp = cross( q1, N );
        vec3 q0perp = cross( N, q0 );
        vec3 T = q1perp * st0.x + q0perp * st1.x;
        vec3 B = q1perp * st0.y + q0perp * st1.y;
        float det = max( dot( T, T ), dot( B, B ) );
        float scale = ( det == 0.0 ) ? 0.0 : inversesqrt( det );
        return mat3( T * scale, B * scale, N );
      }
    ";
    #end
    return "";
  }
}