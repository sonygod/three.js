import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.StringTools;
import haxe.macro.ComplexType;
import haxe.macro.ComplexType.Field;
import haxe.macro.Type;
import haxe.macro.Expr.FieldAccess;
import haxe.macro.Expr.Const;
import haxe.macro.Expr.Ident;

class ToneMapping {

  static function process( code:String, ctx:Context ):Expr {
    var lines = code.split("\n");
    var output = [];

    for (line in lines) {
      var trimmed = StringTools.trim(line);
      if (trimmed.startsWith("#ifndef saturate")) {
        output.push("if(!Std.isOfType(saturate, haxe.macro.Expr)) {");
        output.push("saturate = function(a:Float) :Float { return Math.max(0.0, Math.min(a, 1.0)); };");
        output.push("}");
      } else if (trimmed.startsWith("#endif")) {
        output.push("");
      } else {
        output.push(trimmed);
      }
    }

    var toneMappingExposure = ctx.field("toneMappingExposure", "Float");

    var linearToneMapping = ctx.function("LinearToneMapping", {
      "color": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $linearToneMapping(color:vec3) :vec3 { return saturate(toneMappingExposure * color); }");

    var reinhardToneMapping = ctx.function("ReinhardToneMapping", {
      "color": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $reinhardToneMapping(color:vec3) :vec3 { color *= toneMappingExposure; return saturate(color / (new vec3(1.0) + color)); }");

    var optimizedCineonToneMapping = ctx.function("OptimizedCineonToneMapping", {
      "color": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $optimizedCineonToneMapping(color:vec3) :vec3 { color *= toneMappingExposure; color = Math.max(new vec3(0.0), color - 0.004); return Math.pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), new vec3(2.2)); }");

    var rrtAndODTFit = ctx.function("RRTAndODTFit", {
      "v": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $rrtAndODTFit(v:vec3) :vec3 { var a = v * (v + 0.0245786) - 0.000090537; var b = v * (0.983729 * v + 0.4329510) + 0.238081; return a / b; }");

    var acesFilmicToneMapping = ctx.function("ACESFilmicToneMapping", {
      "color": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $acesFilmicToneMapping(color:vec3) :vec3 { var ACESInputMat = new mat3(new vec3(0.59719, 0.07600, 0.02840), new vec3(0.35458, 0.90834, 0.13383), new vec3(0.04823, 0.01566, 0.83777)); var ACESOutputMat = new mat3(new vec3(1.60475, -0.10208, -0.00327), new vec3(-0.53108, 1.10813, -0.07276), new vec3(-0.07367, -0.00605, 1.07602)); color *= toneMappingExposure / 0.6; color = ACESInputMat * color; color = $rrtAndODTFit(color); color = ACESOutputMat * color; return saturate(color); }");

    var linearRec2020ToLinearSrgb = ctx.const("LINEAR_REC2020_TO_LINEAR_SRGB", ctx.type("mat3"));
    output.push("const LINEAR_REC2020_TO_LINEAR_SRGB = new mat3(new vec3(1.6605, -0.1246, -0.0182), new vec3(-0.5876, 1.1329, -0.1006), new vec3(-0.0728, -0.0083, 1.1187));");

    var linearSrgbToLinearRec2020 = ctx.const("LINEAR_SRGB_TO_LINEAR_REC2020", ctx.type("mat3"));
    output.push("const LINEAR_SRGB_TO_LINEAR_REC2020 = new mat3(new vec3(0.6274, 0.0691, 0.0164), new vec3(0.3293, 0.9195, 0.0880), new vec3(0.0433, 0.0113, 0.8956));");

    var agxDefaultContrastApprox = ctx.function("agxDefaultContrastApprox", {
      "x": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $agxDefaultContrastApprox(x:vec3) :vec3 { var x2 = x * x; var x4 = x2 * x2; return + 15.5 * x4 * x2 - 40.14 * x4 * x + 31.96 * x4 - 6.868 * x2 * x + 0.4298 * x2 + 0.1191 * x - 0.00232; }");

    var agxToneMapping = ctx.function("AgXToneMapping", {
      "color": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $agxToneMapping(color:vec3) :vec3 { const AgXInsetMatrix = new mat3(new vec3(0.856627153315983, 0.137318972929847, 0.11189821299995), new vec3(0.0951212405381588, 0.761241990602591, 0.0767994186031903), new vec3(0.0482516061458583, 0.101439036467562, 0.811302368396859)); const AgXOutsetMatrix = new mat3(new vec3(1.1271005818144368, -0.1413297634984383, -0.14132976349843826), new vec3(-0.11060664309660323, 1.157823702216272, -0.11060664309660294), new vec3(-0.016493938717834573, -0.016493938717834257, 1.2519364065950405)); const AgxMinEv = -12.47393; const AgxMaxEv = 4.026069; color *= toneMappingExposure; color = LINEAR_SRGB_TO_LINEAR_REC2020 * color; color = AgXInsetMatrix * color; color = Math.max(color, 1e-10); color = Math.log2(color); color = (color - AgxMinEv) / (AgxMaxEv - AgxMinEv); color = Math.clamp(color, 0.0, 1.0); color = $agxDefaultContrastApprox(color); color = AgXOutsetMatrix * color; color = Math.pow(Math.max(new vec3(0.0), color), new vec3(2.2)); color = LINEAR_REC2020_TO_LINEAR_SRGB * color; color = Math.clamp(color, 0.0, 1.0); return color; }");

    var neutralToneMapping = ctx.function("NeutralToneMapping", {
      "color": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $neutralToneMapping(color:vec3) :vec3 { const StartCompression = 0.8 - 0.04; const Desaturation = 0.15; color *= toneMappingExposure; var x = Math.min(color.r, Math.min(color.g, color.b)); var offset = x < 0.08 ? x - 6.25 * x * x : 0.04; color -= offset; var peak = Math.max(color.r, Math.max(color.g, color.b)); if (peak < StartCompression) return color; var d = 1.0 - StartCompression; var newPeak = 1.0 - d * d / (peak + d - StartCompression); color *= newPeak / peak; var g = 1.0 - 1.0 / (Desaturation * (peak - newPeak) + 1.0); return Math.mix(color, new vec3(newPeak), g); }");

    var customToneMapping = ctx.function("CustomToneMapping", {
      "color": ctx.type("vec3")
    }, ctx.type("vec3"));
    output.push("function $customToneMapping(color:vec3) :vec3 { return color; }");

    return ctx.createFunction(output.join("\n"), ctx.type("ToneMapping"));
  }
}


**Explanation:**

1. **Imports:**
   - Necessary imports for macro functions like `Expr`, `Context`, `StringTools`, `ComplexType`, `Type`, `FieldAccess`, `Const`, and `Ident` are included.

2. **`ToneMapping` Class:**
   - A class `ToneMapping` is defined to hold the macro processing logic.

3. **`process` Function:**
   - The `process` function takes the JavaScript code (`code`) and the macro context (`ctx`) as input.
   - It splits the code into lines and iterates through them.
   - It handles the following:
     - **`#ifndef saturate` and `#endif`:** Replaces these with Haxe code to define the `saturate` function if it's not already defined.
     - **Other lines:** Simply pushes the trimmed lines to the `output` array.

4. **`toneMappingExposure` Field:**
   - Creates a field named `toneMappingExposure` of type `Float` within the `ToneMapping` class.

5. **Function Definitions:**
   - Each JavaScript function is converted into a corresponding Haxe function using `ctx.function()`.
   - The function names are prefixed with `$` (e.g., `$linearToneMapping`) to make them unique.
   - The function bodies are rewritten with Haxe syntax, using appropriate functions like `Math.max`, `Math.min`, `Math.pow`, `Math.log2`, `Math.clamp`, and `Math.mix`.

6. **Constants:**
   - JavaScript constants (like `LINEAR_REC2020_TO_LINEAR_SRGB`) are converted to Haxe constants using `ctx.const()`.

7. **`createFunction`:**
   - Finally, the `ctx.createFunction()` method is used to create a Haxe function from the generated code and return it.

**How to Use:**

1. **Save the Haxe code:** Save the code above as `ToneMapping.hx`.
2. **Use the macro:** In your Haxe project, import the `ToneMapping` class and use the `process` function:
   
   import ToneMapping;

   class MyShader {
     static function main() {
       var toneMapping = ToneMapping.process(/* Your JavaScript code */);
       // Use the generated toneMapping function
     }
   }