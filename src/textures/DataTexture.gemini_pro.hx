import Texture from "./Texture";
import NearestFilter from "../constants";

class DataTexture extends Texture {

  public var isDataTexture:Bool = true;
  public var image: { data:Dynamic, width:Int, height:Int };
  public var generateMipmaps:Bool = false;
  public var flipY:Bool = false;
  public var unpackAlignment:Int = 1;

  public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic = NearestFilter, minFilter:Dynamic = NearestFilter, anisotropy:Dynamic, colorSpace:Dynamic) {
    super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
    this.image = {data:data, width:width, height:height};
  }
}

export var DataTexture = DataTexture;