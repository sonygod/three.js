import Light from "./Light";

class RectAreaLight extends Light {

  public var isRectAreaLight:Bool = true;
  public var type:String = "RectAreaLight";
  public var width:Float;
  public var height:Float;

  public function new(color:Dynamic, intensity:Float, width:Float = 10, height:Float = 10) {
    super(color, intensity);
    this.width = width;
    this.height = height;
  }

  public function get_power():Float {
    // compute the light's luminous power (in lumens) from its intensity (in nits)
    return intensity * width * height * Math.PI;
  }

  public function set_power(power:Float):Void {
    // set the light's intensity (in nits) from the desired luminous power (in lumens)
    intensity = power / (width * height * Math.PI);
  }

  public function copy(source:RectAreaLight):RectAreaLight {
    super.copy(source);
    width = source.width;
    height = source.height;
    return this;
  }

  public function toJSON(meta:Dynamic):Dynamic {
    var data = super.toJSON(meta);
    data.object.width = width;
    data.object.height = height;
    return data;
  }
}

export class RectAreaLight {
  static inline var power(this:RectAreaLight):Float = this.get_power();
  static inline var power(this:RectAreaLight, value:Float):Float = this.set_power(value);
}