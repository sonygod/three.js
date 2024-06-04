import Texture from "./Texture";
import {ClampToEdgeWrapping, NearestFilter} from "../constants";

class DataArrayTexture extends Texture {

  public var isDataArrayTexture:Bool = true;
  public var image: {data:Dynamic, width:Int, height:Int, depth:Int};
  public var layerUpdates:Set<Int> = new Set();

  public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
    super(null);

    this.image = {data:data, width:width, height:height, depth:depth};

    this.magFilter = NearestFilter;
    this.minFilter = NearestFilter;

    this.wrapR = ClampToEdgeWrapping;

    this.generateMipmaps = false;
    this.flipY = false;
    this.unpackAlignment = 1;
  }

  public function addLayerUpdate(layerIndex:Int) {
    this.layerUpdates.add(layerIndex);
  }

  public function clearLayerUpdates() {
    this.layerUpdates.clear();
  }
}

export class DataArrayTexture {
}