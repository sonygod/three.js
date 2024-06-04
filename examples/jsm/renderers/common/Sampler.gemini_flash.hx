import Binding from "./Binding";

class Sampler extends Binding {

  public var texture:Dynamic;
  public var version:Int;

  public function new(name:String, texture:Dynamic) {
    super(name);
    this.texture = texture;
    this.version = texture != null ? texture.version : 0;
    this.isSampler = true;
  }
}

class Sampler {
  public static inline var isSampler:Bool = true;
}

export default Sampler;