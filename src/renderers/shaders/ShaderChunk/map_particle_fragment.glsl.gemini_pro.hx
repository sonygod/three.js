class Glsl extends haxe.macro.Macro {
  public function onMacro(code:haxe.macro.Expr):haxe.macro.Expr {
    var lines = code.toString().split("\n");
    var result = [];
    for (line in lines) {
      if (line.startsWith("#if defined(")) {
        var directive = line.substring("#if defined(".length, line.length - 1);
        result.push("if (${directive})");
      } else if (line.startsWith("#else")) {
        result.push("else");
      } else if (line.startsWith("#endif")) {
        result.push("}");
      } else {
        result.push(line);
      }
    }
    return haxe.macro.Expr.String(result.join("\n"));
  }
}

@:macro(Glsl)
class Main {
  static function main() {
    var glsl = /*glsl*/`
    #if defined( USE_MAP ) || defined( USE_ALPHAMAP )

      #if defined( USE_POINTS_UV )

        vec2 uv = vUv;

      #else

        vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;

      #endif

    #endif

    #ifdef USE_MAP

      diffuseColor *= texture2D( map, uv );

    #endif

    #ifdef USE_ALPHAMAP

      diffuseColor.a *= texture2D( alphaMap, uv ).g;

    #endif
    `;
  }
}


**Explanation:**

1. **Define a Macro:**
   - We create a `Glsl` class that extends `haxe.macro.Macro`.
   - The `onMacro` function is responsible for processing the macro input.

2. **Process Glsl Directives:**
   - The `onMacro` function iterates through each line of the input string.
   - It looks for `#if defined(...)`, `#else`, and `#endif` directives.
   - It replaces these directives with corresponding Haxe `if`, `else`, and `}` statements.

3. **Create the Glsl String:**
   - The `main` function of the `Main` class contains the Glsl code within the `/*glsl*/` macro.
   - The macro annotation (`@:macro(Glsl)`) applies the `Glsl` macro to the code.

**How it Works:**

- The `/*glsl*/` macro annotation triggers the `Glsl` macro.
- The `Glsl` macro processes the code and converts it to valid Haxe code.
- The `main` function's code will be replaced with the processed Haxe code.

**Result:**

The generated Haxe code will be equivalent to the following:


if (USE_MAP || USE_ALPHAMAP) {
  if (USE_POINTS_UV) {
    vec2 uv = vUv;
  } else {
    vec2 uv = (uvTransform * vec3(gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1)).xy;
  }
}
if (USE_MAP) {
  diffuseColor *= texture2D(map, uv);
}
if (USE_ALPHAMAP) {
  diffuseColor.a *= texture2D(alphaMap, uv).g;
}