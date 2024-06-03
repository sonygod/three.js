import Material from "./Material";
import Color from "../math/Color";

class PointsMaterial extends Material {
  public var isPointsMaterial:Bool = true;
  public var type:String = "PointsMaterial";
  public var color:Color;
  public var map:Dynamic = null;
  public var alphaMap:Dynamic = null;
  public var size:Float = 1;
  public var sizeAttenuation:Bool = true;
  public var fog:Bool = true;

  public function new(parameters:Dynamic = null) {
    super();
    this.color = new Color(0xFFFFFF);
    this.setValues(parameters);
  }

  public function copy(source:PointsMaterial):PointsMaterial {
    super.copy(source);
    this.color = source.color.clone();
    this.map = source.map;
    this.alphaMap = source.alphaMap;
    this.size = source.size;
    this.sizeAttenuation = source.sizeAttenuation;
    this.fog = source.fog;
    return this;
  }
}

export class PointsMaterial {
  public static function new(parameters:Dynamic = null):PointsMaterial {
    return new PointsMaterial(parameters);
  }
}