package three.shader;

class SpecularMapFragment {

  public var specularStrength:Float;

  public function new() {
    #if (USE_SPECULARMAP)

    var texelSpecular = texture2D(specularMap, vSpecularMapUv);
    specularStrength = texelSpecular.r;

    #else

    specularStrength = 1.0;

    #end
  }
}