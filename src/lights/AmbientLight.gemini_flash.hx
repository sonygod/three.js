import three.lights.Light;

class AmbientLight extends Light {
  public var isAmbientLight:Bool;
  public var type:String;

  public function new(color:Dynamic, intensity:Float) {
    super(color, intensity);
    this.isAmbientLight = true;
    this.type = "AmbientLight";
  }
}