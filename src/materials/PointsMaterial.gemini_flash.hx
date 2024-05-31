import three.materials.Material;
import three.math.Color;

class PointsMaterial extends Material {
  public var isPointsMaterial:Bool = true;
  public var type:String = "PointsMaterial";
  public var color:Color;
  public var map:Dynamic;
  public var alphaMap:Dynamic;
  public var size:Float;
  public var sizeAttenuation:Bool;
  public var fog:Bool;

  public function new(parameters:Dynamic = null) {
    super();
    this.color = new Color(0xffffff);
    this.size = 1;
    this.sizeAttenuation = true;
    this.fog = true;

    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  public function copy(source:PointsMaterial):PointsMaterial {
    super.copy(source);
    this.color.copy(source.color);
    this.map = source.map;
    this.alphaMap = source.alphaMap;
    this.size = source.size;
    this.sizeAttenuation = source.sizeAttenuation;
    this.fog = source.fog;
    return this;
  }
}