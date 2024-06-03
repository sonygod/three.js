class Glsl extends haxe.macro.Macro {
  public function onMacro(args : Array<haxe.macro.Expr>) : haxe.macro.Expr {
    var code = """
#ifdef USE_ALPHATEST

	#ifdef ALPHA_TO_COVERAGE

	diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );
	if ( diffuseColor.a == 0.0 ) discard;

	#else

	if ( diffuseColor.a < alphaTest ) discard;

	#endif

#endif
""";
    return haxe.macro.Expr.String(code);
  }
}


This code defines a `Glsl` class that extends `haxe.macro.Macro`. This class implements the `onMacro` function, which takes an array of expressions as arguments and returns a new expression. 

Here's how it works:

1. **Define the macro:** The `Glsl` class is defined as a macro, which means it can be used within Haxe code to generate code at compile time.
2. **Implement `onMacro`:** The `onMacro` function is where the magic happens. It takes the arguments passed to the macro and generates the desired code.
3. **Generate the code:** Inside `onMacro`, the code snippet you provided is enclosed in a string literal. This string represents the GLSL code you want to generate.
4. **Return the generated code:** The function returns an `Expr.String` object containing the generated GLSL code.

Now, you can use the `Glsl` macro in your Haxe code like this:


import Glsl;

class MyShader {
  static function main() {
    var shaderCode = Glsl.make();
    // Use shaderCode to create your shader
  }
}