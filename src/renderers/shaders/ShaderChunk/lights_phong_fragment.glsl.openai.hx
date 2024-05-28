package three.renderers.shaders.ShaderChunk;

class LightsPhongFragment {
  public var material:BlinnPhongMaterial;

  public function new(diffuseColor:Vec3, specular:Float, shininess:Float, specularStrength:Float) {
    material = new BlinnPhongMaterial();
    material.diffuseColor = diffuseColor.rgb();
    material.specularColor = specular;
    material.specularShininess = shininess;
    material.specularStrength = specularStrength;
  }
}