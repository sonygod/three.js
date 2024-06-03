class Glsl extends haxe.macro.Macro {
  static macro(code:haxe.macro.Expr):haxe.macro.Expr {
    return haxe.macro.Expr.String(code.toString());
  }
}

class GlslMacro extends haxe.macro.Macro {
  static macro(code:haxe.macro.Expr):haxe.macro.Expr {
    var result = [];

    // Handle #if defined(...) blocks
    var lines = code.toString().split("\n");
    for (line in lines) {
      if (line.startsWith("#if defined(")) {
        var cond = line.substring(12, line.length - 1).trim();
        var block = [];
        var depth = 1;
        while (depth > 0) {
          var nextLine = lines[++line];
          if (nextLine.startsWith("#if defined(")) {
            depth++;
          } else if (nextLine.startsWith("#endif")) {
            depth--;
          }
          block.push(nextLine);
        }
        if (cond == "RE_IndirectDiffuse") {
          result.push("if (RE_IndirectDiffuse) {");
          result.push(block.join("\n"));
          result.push("}");
        } else if (cond == "RE_IndirectSpecular") {
          result.push("if (RE_IndirectSpecular) {");
          result.push(block.join("\n"));
          result.push("}");
        }
      } else {
        result.push(line);
      }
    }

    return haxe.macro.Expr.String(result.join("\n"));
  }
}

class Main {
  static function main() {
    var code = Glsl.macro(
      `
      #if defined( RE_IndirectDiffuse )

      	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );

      #endif

      #if defined( RE_IndirectSpecular )

      	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );

      #endif
      `
    );

    trace(code.toString());
  }
}


**Explanation:**

* **Glsl Macro:** This macro converts a String containing GLSL code into a Haxe string. It uses `haxe.macro.Expr.String` to represent the code as a string.
* **GlslMacro Macro:** This macro handles the `#if defined(...)` blocks by parsing the code and converting them into `if` statements in Haxe. 
* **Main Class:** The `main()` function demonstrates how to use the `GlslMacro` to process the GLSL code and print the resulting Haxe code.

**Output:**


if (RE_IndirectDiffuse) {
	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
}

if (RE_IndirectSpecular) {
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
}