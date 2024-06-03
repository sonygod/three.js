import LightShadow from "./LightShadow";
import OrthographicCamera from "../cameras/OrthographicCamera";

class DirectionalLightShadow extends LightShadow {

  public function new() {
    super(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
    this.isDirectionalLightShadow = true;
  }

  public var isDirectionalLightShadow:Bool;

}

class DirectionalLightShadow {
  public static function main() {
    var shadow = new DirectionalLightShadow();
    // Use the shadow object
  }
}