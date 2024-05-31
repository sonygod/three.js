class Shader {
  public static function getSource():String {
    var result = "";

    #if USE_COLOR_ALPHA
      result += "vColor = vec4( 1.0 );\n";
    #elseif (USE_COLOR || USE_INSTANCING_COLOR || USE_BATCHING_COLOR)
      result += "vColor = vec3( 1.0 );\n";
    #end

    #if USE_COLOR
      result += "vColor *= color;\n";
    #end

    #if USE_INSTANCING_COLOR
      result += "vColor.xyz *= instanceColor.xyz;\n";
    #end

    #if USE_BATCHING_COLOR
      result += "vec3 batchingColor = getBatchingColor( batchId );\n";
      result += "vColor.xyz *= batchingColor.xyz;\n";
    #end

    return result;
  }
}