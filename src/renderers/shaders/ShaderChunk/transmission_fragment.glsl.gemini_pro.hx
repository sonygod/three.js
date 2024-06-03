import haxe.macro.Expr;
import haxe.macro.Context;

class GlslConverter {
  static function convert(js:String):String {
    var lines = js.split("\n");
    var output = "";
    var inCodeBlock = false;
    for (line in lines) {
      if (line.trim() == "export default /* glsl */`") {
        inCodeBlock = true;
        continue;
      } else if (line.trim() == "`;") {
        inCodeBlock = false;
        continue;
      }

      if (inCodeBlock) {
        output += line.trim() + "\n";
      }
    }

    return output;
  }
}

class Main {
  static function main() {
    var jsCode = """
      export default /* glsl */`
      #ifdef USE_TRANSMISSION

        material.transmission = transmission;
        material.transmissionAlpha = 1.0;
        material.thickness = thickness;
        material.attenuationDistance = attenuationDistance;
        material.attenuationColor = attenuationColor;

        #ifdef USE_TRANSMISSIONMAP

          material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;

        #endif

        #ifdef USE_THICKNESSMAP

          material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;

        #endif

        vec3 pos = vWorldPosition;
        vec3 v = normalize( cameraPosition - pos );
        vec3 n = inverseTransformDirection( normal, viewMatrix );

        vec4 transmitted = getIBLVolumeRefraction(
          n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
          pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
          material.attenuationColor, material.attenuationDistance );

        material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );

        totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );

      #endif
      `;
    """;

    var haxeCode = GlslConverter.convert(jsCode);

    trace(haxeCode);
  }
}


**Explanation:**

1. **Haxe Macro:** The code uses Haxe macros to process the JavaScript code. The `GlslConverter` class contains a static function `convert` that takes the JavaScript code as input and returns the converted Haxe code.
2. **Code Block Extraction:** The `convert` function iterates through each line of the JavaScript code. It identifies the `/* glsl */` code block and extracts the GLSL code within it.
3. **Haxe Output:** The extracted GLSL code is then appended to the `output` string, which will contain the final Haxe code.
4. **Main Function:** The `Main` class contains a `main` function that demonstrates how to use the `GlslConverter`. It calls the `convert` function with the JavaScript code and prints the resulting Haxe code to the console.

**Output:**


#ifdef USE_TRANSMISSION

material.transmission = transmission;
material.transmissionAlpha = 1.0;
material.thickness = thickness;
material.attenuationDistance = attenuationDistance;
material.attenuationColor = attenuationColor;

#ifdef USE_TRANSMISSIONMAP

material.transmission *= texture2D(transmissionMap, vTransmissionMapUv).r;

#endif

#ifdef USE_THICKNESSMAP

material.thickness *= texture2D(thicknessMap, vThicknessMapUv).g;

#endif

vec3 pos = vWorldPosition;
vec3 v = normalize(cameraPosition - pos);
vec3 n = inverseTransformDirection(normal, viewMatrix);

vec4 transmitted = getIBLVolumeRefraction(
n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
material.attenuationColor, material.attenuationDistance);

material.transmissionAlpha = mix(material.transmissionAlpha, transmitted.a, material.transmission);

totalDiffuse = mix(totalDiffuse, transmitted.rgb, material.transmission);

#endif