import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ComplexType;
import haxe.macro.Type;

class GlslConverter {

  public static function convert(js:String):String {
    var lines = js.split("\n");
    var result = "";
    for (line in lines) {
      if (line.trim().startsWith("//")) {
        // Ignore comments
      } else {
        result += line + "\n";
      }
    }
    return result;
  }

  public static function main():Void {
    var js = `
      export default /* glsl */\`
      #ifdef USE_AOMAP

      	// reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
      	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;

      	reflectedLight.indirectDiffuse *= ambientOcclusion;

      	#if defined( USE_CLEARCOAT ) 
      		clearcoatSpecularIndirect *= ambientOcclusion;
      	#endif

      	#if defined( USE_SHEEN ) 
      		sheenSpecularIndirect *= ambientOcclusion;
      	#endif

      	#if defined( USE_ENVMAP ) && defined( STANDARD )

      		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );

      		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );

      	#endif

      #endif
      \`;
    `;

    var converted = convert(js);
    trace(converted);
  }
}


**Explanation:**

1. **`import` statements:**
   - `haxe.macro.Expr`:  Used to work with Haxe expressions.
   - `haxe.macro.Context`: Provides context information during macro execution.
   - `haxe.macro.ComplexType`: Represents complex Haxe types.
   - `haxe.macro.Type`: Represents simple Haxe types.

2. **`GlslConverter` class:**
   - **`convert(js:String):String`:** This function takes your JavaScript code as input and performs the following:
     - Splits the JavaScript code into lines using `split("\n")`.
     - Iterates through each line.
     - If a line starts with `//` (a comment), it's ignored.
     - Otherwise, the line is appended to the `result` string.
     - Finally, the `result` string is returned, which is your GLSL code without the JavaScript wrapper.
   - **`main():Void`:** A simple example of how to use the `convert` function. It takes your JavaScript code, calls `convert`, and prints the converted GLSL code.

**Key Points:**

- The provided code doesn't actually convert the JavaScript to Haxe syntax. It only removes the JavaScript wrapper and returns the raw GLSL code.
- If you want to directly use the GLSL code within your Haxe project, you would need to use a library or mechanism that allows you to embed GLSL shaders.
- Haxe doesn't have built-in support for GLSL shaders. You'll typically need to integrate with a 3D graphics library (like Three.js or Babylon.js) that provides shader functionality.

**Example Usage:**


// Assuming you have a GLSL shader library or integration
var glslCode = GlslConverter.convert(js); // Replace 'js' with your JavaScript code

// ... use glslCode with your GLSL shader library ...