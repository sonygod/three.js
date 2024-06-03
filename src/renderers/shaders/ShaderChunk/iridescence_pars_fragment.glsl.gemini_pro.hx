import haxe.macro.Expr;

class GlslMacro {
  public static function glsl(code:String) {
    return macro {
      Expr.fromString(code)
    };
  }
}

@:build(GlslMacro.glsl)
var glsl =
`
#ifdef USE_IRIDESCENCEMAP

	uniform sampler2D iridescenceMap;

#endif

#ifdef USE_IRIDESCENCE_THICKNESSMAP

	uniform sampler2D iridescenceThicknessMap;

#endif
`;


**Explanation:**

1. **`@:build` Macro:** The `@:build` annotation is used to apply a custom macro during the compilation process.
2. **`GlslMacro` Class:** This class defines the `glsl` macro function.
3. **`glsl(code:String)` Function:** This function receives the GLSL code as a string.
4. **`macro { ... }` Block:** Inside the macro block, we use `Expr.fromString(code)` to convert the string into a Haxe expression.
5. **`glsl` Variable:** This variable holds the GLSL code and is annotated with the `@:build(GlslMacro.glsl)` annotation. This annotation applies the `glsl` macro to the variable, effectively injecting the GLSL code into the compiled Haxe code.

**Usage:**

To use the GLSL code in your Haxe project, simply access the `glsl` variable:


// Access the GLSL code
trace(glsl);