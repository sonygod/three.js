class ShaderUtils {
  public static function getFragmentShader():String {
    #if DITHERING
      return "gl_FragColor.rgb = dithering( gl_FragColor.rgb );";
    #else
      return "";
    #end
  }
}