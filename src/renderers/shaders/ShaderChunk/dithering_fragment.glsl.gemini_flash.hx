class Main {
  public static function main():Void {
    var glsl = "#ifdef DITHERING\n\tgl_FragColor.rgb = dithering( gl_FragColor.rgb );\n\n#endif";
    trace(glsl);
  }
}