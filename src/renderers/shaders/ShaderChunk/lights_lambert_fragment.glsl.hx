package three.shader;

class LightsLambertFragment {
  static public var material:LambertMaterial = new LambertMaterial();
  static public var diffuseColor:Vector3 = new Vector3();
  static public var specularStrength:Float = 0.0;

  static public function getShader():String {
    return '
      LambertMaterial material;
      material.diffuseColor = vec3(${diffuseColor.x}, ${diffuseColor.y}, ${diffuseColor.z});
      material.specularStrength = ${specularStrength};
    ';
  }
}