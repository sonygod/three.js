import Binding from "./Binding";

class SampledTexture extends Binding {
  public var id:Int;
  public var texture:Dynamic;
  public var version:Int;
  public var store:Bool;
  public var isSampledTexture:Bool;

  public function new(name:String, texture:Dynamic) {
    super(name);
    this.id = id++;
    this.texture = texture;
    this.version = texture != null ? texture.version : 0;
    this.store = false;
    this.isSampledTexture = true;
  }

  public function get_needsBindingsUpdate():Bool {
    var texture = this.texture;
    var version = this.version;
    return texture.isVideoTexture ? true : version != texture.version;
    // @TODO: version === 0 && texture.version > 0 ( add it just to External Textures like PNG,JPG )
  }

  public function update():Bool {
    var texture = this.texture;
    var version = this.version;
    if (version != texture.version) {
      this.version = texture.version;
      return true;
    }
    return false;
  }
}

class SampledArrayTexture extends SampledTexture {
  public var isSampledArrayTexture:Bool;

  public function new(name:String, texture:Dynamic) {
    super(name, texture);
    this.isSampledArrayTexture = true;
  }
}

class Sampled3DTexture extends SampledTexture {
  public var isSampled3DTexture:Bool;

  public function new(name:String, texture:Dynamic) {
    super(name, texture);
    this.isSampled3DTexture = true;
  }
}

class SampledCubeTexture extends SampledTexture {
  public var isSampledCubeTexture:Bool;

  public function new(name:String, texture:Dynamic) {
    super(name, texture);
    this.isSampledCubeTexture = true;
  }
}

var id:Int = 0;

export { SampledTexture, SampledArrayTexture, Sampled3DTexture, SampledCubeTexture };