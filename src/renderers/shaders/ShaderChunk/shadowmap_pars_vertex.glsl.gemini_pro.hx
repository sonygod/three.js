import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Macro;
import haxe.macro.Type;

class GlslMacro extends Macro {
  static function get(context:Context, args:Array<Expr>):Expr {
    var code = args[0].toString();

    var result = "";

    var lines = code.split("\n");
    var indentLevel = 0;

    for (line in lines) {
      var trimmedLine = line.trim();
      if (trimmedLine.startsWith("#if")) {
        indentLevel++;
        result += "\t".repeat(indentLevel) + trimmedLine + "\n";
      } else if (trimmedLine.startsWith("#endif")) {
        indentLevel--;
        result += "\t".repeat(indentLevel) + trimmedLine + "\n";
      } else if (trimmedLine.length > 0) {
        result += "\t".repeat(indentLevel) + trimmedLine + "\n";
      }
    }

    return Context.makeString(result);
  }
}

class Glsl {
  static macro function glsl(code:String):String {
    return GlslMacro.get(Context.current, [Context.makeString(code)]);
  }
}

class Main {
  static function main() {
    var code = Glsl.glsl(`
      #if NUM_SPOT_LIGHT_COORDS > 0

        uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];
        varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];

      #endif

      #ifdef USE_SHADOWMAP

        #if NUM_DIR_LIGHT_SHADOWS > 0

          uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];
          varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];

          struct DirectionalLightShadow {
            float shadowBias;
            float shadowNormalBias;
            float shadowRadius;
            vec2 shadowMapSize;
          };

          uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];

        #endif

        #if NUM_SPOT_LIGHT_SHADOWS > 0

          struct SpotLightShadow {
            float shadowBias;
            float shadowNormalBias;
            float shadowRadius;
            vec2 shadowMapSize;
          };

          uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];

        #endif

        #if NUM_POINT_LIGHT_SHADOWS > 0

          uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];
          varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];

          struct PointLightShadow {
            float shadowBias;
            float shadowNormalBias;
            float shadowRadius;
            vec2 shadowMapSize;
            float shadowCameraNear;
            float shadowCameraFar;
          };

          uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];

        #endif

        /*
        #if NUM_RECT_AREA_LIGHTS > 0

          // TODO (abelnation): uniforms for area light shadows

        #endif
        */

      #endif
    `);

    trace(code);
  }
}


**Explanation:**

1. **GlslMacro:** This class defines a macro named `GlslMacro` which takes a single argument, a string representing the GLSL code.
2. **get() Function:** The `get()` function of the `GlslMacro` class performs the following:
   - Takes the input GLSL code and splits it into lines.
   - Iterates through each line, keeping track of the indentation level.
   - For lines starting with `#if` or `#endif`, it adds the line to the output with the appropriate indentation.
   - For other lines, it adds them to the output with indentation.
   - Finally, it returns the constructed string.
3. **Glsl Class:** This class provides a static macro function `glsl()`.
   - When called, it calls the `get()` function of `GlslMacro` with the input GLSL code as an argument.
4. **Main Class:** This class demonstrates how to use the `glsl()` macro.
   - It defines a string containing the GLSL code.
   - It calls the `glsl()` macro with this code and prints the resulting string.

**Usage:**

To use the macro, simply call the `glsl()` function with the GLSL code as an argument:


var glslCode = Glsl.glsl(`
  // Your GLSL code here
`);