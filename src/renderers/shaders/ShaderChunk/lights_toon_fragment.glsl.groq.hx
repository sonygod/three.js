package three.shader;

class LightsToonFragment {
  public function new() {}

  public static var shader:String = "
    uniform vec3 diffuseColor;
    void main() {
      ToonMaterial material;
      material.diffuseColor = diffuseColor.rgb;
    }
  ";
}