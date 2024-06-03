class MyShader {
  public static function getShader():String {
    return /* glsl */
      "LambertMaterial material;\n" +
      "material.diffuseColor = diffuseColor.rgb;\n" +
      "material.specularStrength = specularStrength;\n";
  }
}