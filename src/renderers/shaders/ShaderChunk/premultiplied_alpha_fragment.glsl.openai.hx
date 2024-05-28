import haxe.glsl.Glsl;

class PremultipliedAlphaFragmentShader {
  public static var shader:Glsl = '
#ifdef PREMULTIPLIED_ALPHA
  void main() {
    gl_FragColor.rgb *= gl_FragColor.a;
  }
#endif
';
}