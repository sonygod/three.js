class ShaderChunk_lights_lambert_fragment {
  var material: Material;

  public function new() {
    material = new Material();
  }

  public function setMaterial(diffuseColor: Color, specularStrength: Float) {
    material.diffuseColor = diffuseColor.rgb;
    material.specularStrength = specularStrength;
  }
}

class Material {
  public var diffuseColor: Float;
  public var specularStrength: Float;
}

class Color {
  public var rgb: Float;
}