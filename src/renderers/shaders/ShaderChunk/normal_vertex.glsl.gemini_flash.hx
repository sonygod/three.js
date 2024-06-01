class ShaderUtil {
  public static function getVertexNormal():String {
    var result:String = "";
    #if !FLAT_SHADED
      result += "vNormal = normalize( transformedNormal );\n";
      #if USE_TANGENT
      result += "vTangent = normalize( transformedTangent );\n";
      result += "vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );\n";
      #end
    #end
    return result;
  }
}