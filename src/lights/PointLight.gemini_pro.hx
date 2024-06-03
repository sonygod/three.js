import Light from "./Light";
import PointLightShadow from "./PointLightShadow";

class PointLight extends Light {

  public var isPointLight:Bool = true;
  public var type:String = "PointLight";
  public var distance:Float;
  public var decay:Float;
  public var shadow:PointLightShadow;

  public function new(color:Dynamic, intensity:Float, distance:Float = 0, decay:Float = 2) {
    super(color, intensity);
    this.distance = distance;
    this.decay = decay;
    this.shadow = new PointLightShadow();
  }

  public function get power():Float {
    return this.intensity * 4 * Math.PI;
  }

  public function set power(power:Float) {
    this.intensity = power / (4 * Math.PI);
  }

  public function dispose() {
    this.shadow.dispose();
  }

  public function copy(source:PointLight, recursive:Bool = false):PointLight {
    super.copy(source, recursive);
    this.distance = source.distance;
    this.decay = source.decay;
    this.shadow = source.shadow.clone();
    return this;
  }
}

export default PointLight;