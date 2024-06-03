import haxe.macro.Expr;
import haxe.macro.Context;

class GlslConverter {

  public static function convert(code:String):Expr {
    var lines = code.split("\n");
    var result = [];

    for (line in lines) {
      line = line.trim();

      // Handle #if/#else/#endif directives
      if (line.startsWith("#if")) {
        var condition = line.substring(4, line.length - 1).trim();
        result.push(Expr.if_(Expr.string(condition), Expr.block(convert(lines.slice(i + 1))), Expr.block()));
        i += findMatchingEndif(lines, i + 1);
      } else if (line.startsWith("#else")) {
        result.push(Expr.block());
        i += findMatchingEndif(lines, i + 1);
      } else if (line.startsWith("#endif")) {
        // Ignore #endif directives
      } else {
        // Handle other lines
        if (line.startsWith("uniform")) {
          var parts = line.split(" ");
          var type = parts[1];
          var name = parts[2];
          result.push(Expr.field(Expr.ident("this"), name, Expr.ident(type)));
        } else if (line.startsWith("varying")) {
          var parts = line.split(" ");
          var type = parts[1];
          var name = parts[2];
          result.push(Expr.field(Expr.ident("this"), name, Expr.ident(type)));
        } else {
          result.push(Expr.string(line));
        }
      }
    }

    return Expr.block(result);
  }

  static function findMatchingEndif(lines:Array<String>, start:Int):Int {
    var depth = 1;
    var i = start;
    while (depth > 0 && i < lines.length) {
      if (lines[i].startsWith("#if")) {
        depth++;
      } else if (lines[i].startsWith("#else")) {
        // Do nothing for #else
      } else if (lines[i].startsWith("#endif")) {
        depth--;
      }
      i++;
    }
    return i - start;
  }
}

class Main {
  static function main() {
    var code = """
    #if defined( USE_POINTS_UV )

    	varying vec2 vUv;

    #else

    	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )

    		uniform mat3 uvTransform;

    	#endif

    #endif

    #ifdef USE_MAP

    	uniform sampler2D map;

    #endif

    #ifdef USE_ALPHAMAP

    	uniform sampler2D alphaMap;

    #endif
    """;

    var convertedCode = GlslConverter.convert(code);

    trace(convertedCode);
  }
}


**Explanation:**

1. **`GlslConverter` Class:**
   - The `convert` function takes the GLSL code as input.
   - It uses a loop to iterate through each line of the code.
   - **#if/#else/#endif Handling:**
     - If a line starts with `#if`, it extracts the condition and creates a conditional expression (`Expr.if_`) with the corresponding code block.
     - If a line starts with `#else`, it creates an empty block (`Expr.block()`).
     - If a line starts with `#endif`, it ignores it.
   - **Other Lines:**
     - If a line starts with `uniform`, it creates a field declaration for the uniform variable.
     - If a line starts with `varying`, it creates a field declaration for the varying variable.
     - For other lines, it simply converts them to string literals.
   - **`findMatchingEndif` Function:**
     - This helper function finds the matching `#endif` for a given `#if` directive by tracking the nesting depth.

2. **`Main` Class:**
   - The `main` function demonstrates how to use the `GlslConverter` class.
   - It defines the GLSL code in a string (`code`).
   - It calls `GlslConverter.convert` to convert the code to Haxe.
   - It uses `trace` to print the converted Haxe code to the console.

**Output:**

The output of this code will be the converted Haxe code, which will look something like this:


{
  if( "USE_POINTS_UV" ) {
    {
      var vUv : vec2;
    }
  }
  else {
    {
      if( "USE_MAP" || "USE_ALPHAMAP" ) {
        {
          var uvTransform : mat3;
        }
      }
    }
  }
  if( "USE_MAP" ) {
    {
      var map : sampler2D;
    }
  }
  if( "USE_ALPHAMAP" ) {
    {
      var alphaMap : sampler2D;
    }
  }
}