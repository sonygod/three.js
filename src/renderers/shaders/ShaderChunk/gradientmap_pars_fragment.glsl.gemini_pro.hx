import haxe.macro.Expr;
import haxe.macro.Context;

class GlslConverter {

	static function convert(js:String):String {
		var lines = js.split("\n");
		var result = new StringBuf();
		for (line in lines) {
			if (line.trim() == "") continue;
			if (line.startsWith("export default")) {
				// Remove export default
				result.add(line.split("export default")[1].trim());
			} else if (line.startsWith("// glsl")) {
				// Remove // glsl
				result.add(line.split("// glsl")[1].trim());
			} else {
				result.add(line.trim());
			}
		}
		return result.toString();
	}

	static macro function glsl(expr:Expr):Expr {
		var code = Context.getExpression(expr);
		return Context.createExpr(convert(code));
	}
}

@:glsl("
#ifdef USE_GRADIENTMAP

	uniform sampler2D gradientMap;

#endif

vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {

	// dotNL will be from -1.0 to 1.0
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );

	#ifdef USE_GRADIENTMAP

		return vec3( texture2D( gradientMap, coord ).r );

	#else

		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );

	#endif

}
")
class GlslCode {
}



This code does the following:

1. **`GlslConverter` class:**
   - This class is responsible for converting the JavaScript code to Haxe.
   - The `convert()` function does the following:
     - Splits the JavaScript string into lines.
     - Iterates through each line:
       - Removes `export default` and `// glsl` comments.
       - Appends the remaining line to the `result` string buffer.
   - The `glsl()` macro uses the `convert()` function to convert the provided JavaScript code to Haxe.

2. **`glsl()` Macro:**
   - This macro takes a string expression (containing JavaScript code) as input.
   - It calls the `GlslConverter.convert()` function to convert the JavaScript code to Haxe.
   - It then returns a new Haxe expression with the converted code.

3. **`GlslCode` class:**
   - This class is a dummy class used to hold the converted code.
   - The `@:glsl` annotation applies the `glsl()` macro to the class, injecting the converted code into the class.

**How to use:**

1. **Import the `GlslConverter` class:**
   
   import GlslConverter;
   

2. **Use the `@:glsl` annotation:**
   
   @:glsl("
       // your GLSL code here
   ")
   class MyShader {
       // ...
   }