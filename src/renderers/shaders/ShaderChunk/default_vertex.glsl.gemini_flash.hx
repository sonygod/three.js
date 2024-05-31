class Main {
  public static function main(): Void {
    // Haxe doesn't have a direct equivalent to JavaScript template literals with backticks.
    // You can use regular strings with escaped newlines.

    var glslCode:String = 
      "void main() {\n" +
      "  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
      "}";

    // Use the glslCode string as needed.
  }
}