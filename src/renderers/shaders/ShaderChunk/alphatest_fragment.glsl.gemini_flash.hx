package ;

class Main {
  public static function main():Void {
    // Haxe does not have a direct equivalent of GLSL preprocessor directives.
    // You'll need to handle these conditionally within your Haxe code.

    // Example of how to conditionally apply the alpha test:
    var useAlphaTest:Bool = true; // Determine if USE_ALPHATEST should be applied
    var alphaToCoverage:Bool = false; // Determine if ALPHA_TO_COVERAGE should be applied

    var fragmentShaderCode:String = "";

    if (useAlphaTest) {
      if (alphaToCoverage) {
        fragmentShaderCode += "diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );\n";
        fragmentShaderCode += "if ( diffuseColor.a == 0.0 ) discard;\n";
      } else {
        fragmentShaderCode += "if ( diffuseColor.a < alphaTest ) discard;\n";
      }
    }

    // ... rest of your shader code ...

    // Use the generated fragmentShaderCode in your Haxe shader setup
  }
}