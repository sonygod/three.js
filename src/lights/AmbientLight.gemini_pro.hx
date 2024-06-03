import Light from "Light";

class AmbientLight extends Light {

  public var isAmbientLight:Bool = true;
  public var type:String = "AmbientLight";

  public function new(color:Dynamic, intensity:Dynamic) {
    super(color, intensity);
  }
}

class AmbientLight {
  public static var AmbientLight:AmbientLight;
}