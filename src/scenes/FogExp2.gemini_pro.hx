import Color from "../math/Color";

class FogExp2 {

  public var isFogExp2:Bool = true;
  public var name:String = "";
  public var color:Color;
  public var density:Float;

  public function new(color:Color, density:Float = 0.00025) {
    this.color = new Color(color);
    this.density = density;
  }

  public function clone():FogExp2 {
    return new FogExp2(this.color, this.density);
  }

  public function toJSON(?meta:Dynamic):Dynamic {
    return {
      type: "FogExp2",
      name: this.name,
      color: this.color.getHex(),
      density: this.density
    };
  }
}

export class FogExp2;