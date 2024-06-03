import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Macro;

class GlslShader extends Macro {
  static function glsl(ctx:Context, expr:Expr):Expr {
    var code = expr.toString();
    var lines = code.split("\n");
    var buffer = new StringBuf();
    for (line in lines) {
      buffer.add(line);
      buffer.add("\n");
    }
    return Macro.createExpr(ctx, {
      "expr": buffer.toString()
    });
  }

  static function main(ctx:Context, expr:Expr):Expr {
    var code = expr.toString();
    var lines = code.split("\n");
    var buffer = new StringBuf();

    // Replace `#if` directives with Haxe conditionals
    var inIfBlock = false;
    var ifBlockDepth = 0;
    var ifBlockName = "";
    for (line in lines) {
      if (line.startsWith("#if")) {
        ifBlockName = line.split(" ")[1].trim();
        ifBlockDepth++;
        inIfBlock = true;
        buffer.add("if(");
        buffer.add(ifBlockName);
        buffer.add(") {");
        buffer.add("\n");
      } else if (line.startsWith("#else")) {
        buffer.add("} else {");
        buffer.add("\n");
      } else if (line.startsWith("#endif")) {
        buffer.add("}");
        buffer.add("\n");
        inIfBlock = false;
        ifBlockDepth--;
        ifBlockName = "";
      } else {
        if (inIfBlock) {
          buffer.add("  ");
        }
        buffer.add(line);
        buffer.add("\n");
      }
    }

    // Replace `varying` directives with `out`
    var output = buffer.toString().replace(/varying/g, "out");

    // Replace `uniform` directives with `uniform`
    output = output.replace(/uniform/g, "uniform");

    // Replace `sampler2D` with `Sampler2D`
    output = output.replace(/sampler2D/g, "Sampler2D");

    // Replace `vec2` with `Vec2`
    output = output.replace(/vec2/g, "Vec2");

    // Replace `vec3` with `Vec3`
    output = output.replace(/vec3/g, "Vec3");

    // Replace `vec4` with `Vec4`
    output = output.replace(/vec4/g, "Vec4");

    // Replace `float` with `Float`
    output = output.replace(/float/g, "Float");

    // Replace `texture2D` with `texture2D`
    output = output.replace(/texture2D/g, "texture2D");

    // Replace `texture2DCompare` with `texture2DCompare`
    output = output.replace(/texture2DCompare/g, "texture2DCompare");

    // Replace `texture2DDistribution` with `texture2DDistribution`
    output = output.replace(/texture2DDistribution/g, "texture2DDistribution");

    // Replace `unpackRGBAToDepth` with `unpackRGBAToDepth`
    output = output.replace(/unpackRGBAToDepth/g, "unpackRGBAToDepth");

    // Replace `unpackRGBATo2Half` with `unpackRGBATo2Half`
    output = output.replace(/unpackRGBATo2Half/g, "unpackRGBATo2Half");

    // Replace `step` with `step`
    output = output.replace(/step/g, "step");

    // Replace `clamp` with `clamp`
    output = output.replace(/clamp/g, "clamp");

    // Replace `max` with `Math.max`
    output = output.replace(/max/g, "Math.max");

    // Replace `min` with `Math.min`
    output = output.replace(/min/g, "Math.min");

    // Replace `length` with `Math.sqrt`
    output = output.replace(/length/g, "Math.sqrt");

    // Replace `normalize` with `normalize`
    output = output.replace(/normalize/g, "normalize");

    // Replace `sign` with `Math.sign`
    output = output.replace(/sign/g, "Math.sign");

    // Replace `fract` with `Math.fract`
    output = output.replace(/fract/g, "Math.fract");

    // Replace `mix` with `Math.mix`
    output = output.replace(/mix/g, "Math.mix");

    // Replace `cubeToUV` with `cubeToUV`
    output = output.replace(/cubeToUV/g, "cubeToUV");

    return Macro.createExpr(ctx, {
      "expr": output
    });
  }
}


**Explanation:**

1. **Macro Definition:**
   - The code defines a `GlslShader` class that extends the `Macro` class. This allows us to create custom macros for Haxe.

2. **`glsl` Macro:**
   - This macro takes a string expression containing GLSL code and returns it as a string literal expression. This preserves the original GLSL code within Haxe code.

3. **`main` Macro:**
   - This macro is the core of the conversion. It takes a string expression containing GLSL code and performs the following transformations:
     - **`#if` Directives:** Replaces GLSL `#if` directives with Haxe `if` statements.
     - **`varying` Directives:** Replaces `varying` directives with `out`.
     - **`uniform` Directives:** Replaces `uniform` directives with `uniform`.
     - **Type Conversions:** Converts GLSL types like `sampler2D`, `vec2`, `vec3`, `vec4`, and `float` to their corresponding Haxe types (`Sampler2D`, `Vec2`, `Vec3`, `Vec4`, `Float`).
     - **Function Conversions:** Converts built-in GLSL functions to their Haxe equivalents, e.g., `texture2D`, `texture2DCompare`, `texture2DDistribution`, `unpackRGBAToDepth`, `unpackRGBATo2Half`, `step`, `clamp`, `max`, `min`, `length`, `normalize`, `sign`, `fract`, `mix`, `cubeToUV`.

4. **Output:**
   - The `main` macro returns a string expression containing the converted Haxe code.

**To Use the Macro:**

1. **Save the code as `GlslShader.hx`:**
   - Create a new file named `GlslShader.hx` and paste the code into it.

2. **Include the file in your Haxe project:**
   - Add the following line to your `haxelib.json`:
     json
     "source": [
       "GlslShader.hx"
     ]
     
   - Or, add the following line to your `Build.hx` file:
     
     class Build {
       static function main() {
         new haxe.macro.Context().run(new GlslShader());
       }
     }
     

3. **Use the `glsl` macro in your code:**
   - Within your Haxe code, use the `glsl` macro to encapsulate your GLSL code:
     
     var shader = glsl`
       // Your GLSL code here
     `;