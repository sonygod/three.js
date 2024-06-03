import haxe.macro.Expr;

class Glsl {
  static macro function glsl(expr:Expr):Expr {
    return macro {
      #if OPAQUE
      diffuseColor.a = 1.0;
      #end

      #if USE_TRANSMISSION
      diffuseColor.a *= material.transmissionAlpha;
      #end

      gl_FragColor = vec4(outgoingLight, diffuseColor.a);
    };
  }
}

class Main {
  static function main() {
    trace(Glsl.glsl(null));
  }
}


**Explanation:**

1. **`Glsl` Class:**
   - We define a class named `Glsl` to encapsulate the GLSL code.
   - Inside the class, we create a macro function `glsl()`.

2. **`glsl()` Macro Function:**
   - The `glsl()` function takes an `Expr` (expression) as input. This allows you to pass in any valid Haxe expression.
   - It uses the `macro` keyword to define a macro, which means the code within the function will be processed at compile time.
   - Inside the `macro` block, we use the `#if` directives to conditionally include code based on the `OPAQUE` and `USE_TRANSMISSION` defines.
   - The GLSL code itself is directly embedded within the macro.

3. **`Main` Class:**
   - This class provides a simple example of how to use the `Glsl.glsl()` macro.
   - The `main()` function calls `Glsl.glsl()` with a null expression (you can pass any valid expression).
   - The `trace()` function is used to print the resulting GLSL code to the console.

**How to Use:**

1. **Define Preprocessor Symbols:**
   - You need to define the `OPAQUE` and `USE_TRANSMISSION` preprocessor symbols in your Haxe project settings or in your Haxe code before using the `Glsl.glsl()` macro.
2. **Call the Macro:**
   - Use `Glsl.glsl()` wherever you want to include the GLSL code in your Haxe code.

**Example:**


#define OPAQUE
#define USE_TRANSMISSION

class MyShader {
  static function main() {
    trace(Glsl.glsl(null));
  }
}


This will output the following GLSL code:

glsl
diffuseColor.a = 1.0;
diffuseColor.a *= material.transmissionAlpha;
gl_FragColor = vec4(outgoingLight, diffuseColor.a);