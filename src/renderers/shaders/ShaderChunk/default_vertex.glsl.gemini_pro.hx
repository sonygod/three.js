class Main {
  public static function main():Void {
    // Haxe doesn't have template literals with /* glsl */ syntax.
    // You will need to use a string literal.
    var glslCode:String = 
      "void main() {\n" +
      "	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
      "}\n";
  }
}