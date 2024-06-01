class ShaderUtil {
  public static function getPointShaderFragment():String {
    var result:String = "";

    result += "#if defined(USE_MAP) || defined(USE_ALPHAMAP)\n";

    result += "#if defined(USE_POINTS_UV)\n";
    result += "\tvec2 uv = vUv;\n";
    result += "#else\n";
    result += "\tvec2 uv = (uvTransform * vec3(gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1)).xy;\n";
    result += "#end\n";

    result += "#end\n";

    result += "#ifdef USE_MAP\n";
    result += "\tdiffuseColor *= texture2D(map, uv);\n";
    result += "#end\n";

    result += "#ifdef USE_ALPHAMAP\n";
    result += "\tdiffuseColor.a *= texture2D(alphaMap, uv).g;\n";
    result += "#end\n";

    return result;
  }
}