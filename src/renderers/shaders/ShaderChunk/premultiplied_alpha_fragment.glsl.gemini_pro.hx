class ShaderUtil {
  public static function getFragmentShader(): String {
    #if PREMULTIPLIED_ALPHA
      return "gl_FragColor.rgb *= gl_FragColor.a;";
    #else
      return "";
    #end
  }
}