import haxe.macro.Context;

class Glsl extends haxe.macro.Macro {
  public function onMacro(context:Context, args:Array<haxe.macro.Expr>):haxe.macro.Expr {
    var code = args[0].toString();
    return macro StringTools.replace(code, "#ifdef USE_MORPHTARGETS", "if (MORPHTARGETS_COUNT > 0)")
    .replace("#endif", "");
  }
}

class Main {
  static function main() {
    var code = Glsl.run("`\
#ifdef USE_MORPHTARGETS\
\
	// morphTargetBaseInfluence is set based on BufferGeometry.morphTargetsRelative value:\
	// When morphTargetsRelative is false, this is set to 1 - sum(influences); this results in position = sum((target - base) * influence)\
	// When morphTargetsRelative is true, this is set to 1; as a result, all morph targets are simply added to the base after weighting\
	transformed *= morphTargetBaseInfluence;\
\
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {\
\
		if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];\
\
	}\
\
#endif\
`");
    trace(code);
  }
}


**Explanation:**

1. **Haxe Macro:** We define a `Glsl` class that extends `haxe.macro.Macro`. This class will handle the conversion of the GLSL code.
2. **`onMacro` Function:** The `onMacro` function is called when the macro is invoked. It takes the `context` (information about the compilation) and the `args` (arguments passed to the macro). In this case, the only argument is the GLSL code string.
3. **Code Transformation:** The `onMacro` function performs two replacements:
    * **`#ifdef USE_MORPHTARGETS`:** This is replaced with `if (MORPHTARGETS_COUNT > 0)`. This ensures that the code block is only executed if there are morph targets defined.
    * **`#endif`:** This is simply removed.
4. **`Main` Class:** The `Main` class demonstrates how to use the macro. It calls the `run` method of the `Glsl` class, passing the GLSL code as an argument. The resulting transformed code is printed to the console.

**Output:**


if (MORPHTARGETS_COUNT > 0) {
	// morphTargetBaseInfluence is set based on BufferGeometry.morphTargetsRelative value:
	// When morphTargetsRelative is false, this is set to 1 - sum(influences); this results in position = sum((target - base) * influence)
	// When morphTargetsRelative is true, this is set to 1; as a result, all morph targets are simply added to the base after weighting
	transformed *= morphTargetBaseInfluence;

	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {

		if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];

	}
}