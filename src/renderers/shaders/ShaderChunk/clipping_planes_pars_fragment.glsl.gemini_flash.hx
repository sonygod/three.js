class Shader {
  public static function main(): String {
    return
      "#if macro(NUM_CLIPPING_PLANES) > 0\n" +
      "\n" +
      "	varying vec3 vClipPosition;\n" +
      "\n" +
      "	uniform vec4 clippingPlanes[macro(NUM_CLIPPING_PLANES)];\n" +
      "\n" +
      "#end\n";
  }
}