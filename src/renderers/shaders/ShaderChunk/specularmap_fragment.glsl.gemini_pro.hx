class Glsl {
  static function getSpecularStrength():String {
    return """
      float specularStrength;

      #ifdef USE_SPECULARMAP

        vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
        specularStrength = texelSpecular.r;

      #else

        specularStrength = 1.0;

      #endif
    """;
  }
}


**Explanation:**

* **Class Structure:** We create a class `Glsl` to encapsulate the GLSL code.
* **Static Function:** The `getSpecularStrength()` function is declared as `static`, making it a class method accessible without creating an instance of the class.
* **String Literal:** The GLSL code is enclosed in a triple-quoted string literal (