class ShaderUtil {
  public static function getVertexShader(): String {
    var shaderCode: String = "";

    #if (USE_COLOR_ALPHA)
      shaderCode += "varying vec4 vColor;";
    #elseif (USE_COLOR || USE_INSTANCING_COLOR || USE_BATCHING_COLOR)
      shaderCode += "varying vec3 vColor;";
    #end

    return shaderCode;
  }
}