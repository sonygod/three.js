package three.renderers.shaders.ShaderChunk;

class PremultipliedAlphaFragment {

  public static function main() {

    #if (PREMULTIPLIED_ALPHA)

      // Get get normal blending with premultipled, use with CustomBlending, OneFactor, OneMinusSrcAlphaFactor, AddEquation.
      gl_FragColor.rgb *= gl_FragColor.a;

    #end

    return "";
  }

}