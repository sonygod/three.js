class Main {
  public static function main():Void {
    var glsl = 'BlinnPhongMaterial material;\n' +
               'material.diffuseColor = diffuseColor.rgb;\n' +
               'material.specularColor = specular;\n' +
               'material.specularShininess = shininess;\n' +
               'material.specularStrength = specularStrength;';

    // Use the 'glsl' variable as needed
    trace(glsl);
  }
}