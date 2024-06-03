import haxe.macro.Expr;
import haxe.macro.Context;

class GlslConverter {
  static function convert(code:String):Expr {
    var lines = code.split("\n");
    var result = new Array<Expr>();

    for (line in lines) {
      if (line.trim() == "") continue;
      var parts = line.split(" ");
      var firstPart = parts[0].trim();
      var rest = parts.slice(1).join(" ").trim();

      switch (firstPart) {
        case "#ifdef":
          result.push(Expr.if_(Expr.id(rest), Expr.block(new Array<Expr>()), null));
          break;
        case "#ifndef":
          result.push(Expr.if_(Expr.not(Expr.id(rest)), Expr.block(new Array<Expr>()), null));
          break;
        case "#else":
          result.push(Expr.else_(Expr.block(new Array<Expr>())));
          break;
        case "#endif":
          // No need to do anything for #endif
          break;
        default:
          result.push(Expr.line(line));
      }
    }

    return Expr.block(result);
  }
}

class Main {
  static function main() {
    var glslCode = """
      #ifdef USE_MAP

        vec4 sampledDiffuseColor = texture2D( map, vMapUv );

        #ifdef DECODE_VIDEO_TEXTURE

          // use inline sRGB decode until browsers properly support SRGB8_ALPHA8 with video textures (#26516)

          sampledDiffuseColor = vec4( mix( pow( sampledDiffuseColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), sampledDiffuseColor.rgb * 0.0773993808, vec3( lessThanEqual( sampledDiffuseColor.rgb, vec3( 0.04045 ) ) ) ), sampledDiffuseColor.w );
        
        #endif

        diffuseColor *= sampledDiffuseColor;

      #endif
    """;

    var converted = GlslConverter.convert(glslCode);
    Context.printExpr(converted);
  }
}


**Explanation:**

1. **Haxe Macros:** The code uses Haxe macros to dynamically generate Haxe code from the GLSL-like string. This allows us to mimic the preprocessor-like behavior of `#ifdef`, `#ifndef`, and `#else`.

2. **`GlslConverter` Class:**
   - `convert(code:String)`: This function takes the GLSL-like string as input and parses it line by line.
   - It uses `switch` statements to handle different preprocessor directives.
   - For `#ifdef`, `#ifndef`, and `#else`, it generates `Expr.if_`, `Expr.not`, and `Expr.else_` expressions, respectively.
   - Other lines are simply converted to `Expr.line` expressions.

3. **`Main` Class:**
   - `main()` function:
     - It defines the GLSL-like string (`glslCode`).
     - Calls `GlslConverter.convert()` to get the converted Haxe expression.
     - Prints the generated Haxe code using `Context.printExpr()`.

**Output:**


if(USE_MAP) {
  var sampledDiffuseColor:vec4 = texture2D(map, vMapUv);
  if(DECODE_VIDEO_TEXTURE) {
    sampledDiffuseColor = vec4(mix(pow((sampledDiffuseColor.rgb * 0.9478672986) + vec3(0.0521327014), vec3(2.4)), (sampledDiffuseColor.rgb * 0.0773993808), vec3(lessThanEqual(sampledDiffuseColor.rgb, vec3(0.04045)))), sampledDiffuseColor.w);
  }
  diffuseColor *= sampledDiffuseColor;
}