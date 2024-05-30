package three.js.examples.jsm.loaders;

import three.Data3DTexture;
import three.FileLoader;
import three.FloatType;
import three.LinearFilter;
import three.Loader;
import three.UnsignedByteType;
import three.Vector3;
import three.Wrapping.ClampToEdgeWrapping;

class LUTCubeLoader extends Loader {
  public var type:UInt8 = UnsignedByteType;

  public function new(manager:Loader) {
    super(manager);
  }

  public function setType(type:UInt8):LUTCubeLoader {
    if (type != UnsignedByteType && type != FloatType) {
      throw new Error("LUTCubeLoader: Unsupported type");
    }
    this.type = type;
    return this;
  }

  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Error->Void):Void {
    var loader = new FileLoader(this.manager);
    loader.setPath(this.path);
    loader.setResponseType("text");
    loader.load(url, function(text:String) {
      try {
        onLoad(parse(text));
      } catch (e:Error) {
        if (onError != null) {
          onError(e);
        } else {
          trace(e.message);
        }
        this.manager.itemError(url);
      }
    }, onProgress, onError);
  }

  private function parse(input:String):{title:String, size:Int, domainMin:Vector3, domainMax:Vector3, texture3D:Data3DTexture} {
    var regExpTitle = ~/TITLE +"([^"]*)"/;
    var regExpSize = ~/LUT_3D_SIZE +(\d+)/;
    var regExpDomainMin = ~/DOMAIN_MIN +([\d.]+) +([\d.]+) +([\d.]+)/;
    var regExpDomainMax = ~/DOMAIN_MAX +([\d.]+) +([\d.]+) +([\d.]+)/;
    var regExpDataPoints = ~/^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

    var result = regExpTitle.exec(input);
    var title = (result != null) ? result[1] : null;

    result = regExpSize.exec(input);
    if (result == null) {
      throw new Error("LUTCubeLoader: Missing LUT_3D_SIZE information");
    }

    var size = Std.parseInt(result[1]);
    var length = size * size * size * 4;
    var data:Array<Float> = (type == UnsignedByteType) ? new Array<UInt>(length) : new Array<Float>(length);

    var domainMin = new Vector3(0, 0, 0);
    var domainMax = new Vector3(1, 1, 1);

    result = regExpDomainMin.exec(input);
    if (result != null) {
      domainMin.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
    }

    result = regExpDomainMax.exec(input);
    if (result != null) {
      domainMax.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
    }

    if (domainMin.x > domainMax.x || domainMin.y > domainMax.y || domainMin.z > domainMax.z) {
      throw new Error("LUTCubeLoader: Invalid input domain");
    }

    var scale = (type == UnsignedByteType) ? 255 : 1;
    var i:Int = 0;

    while ((result = regExpDataPoints.exec(input)) != null) {
      data[i++] = Std.parseFloat(result[1]) * scale;
      data[i++] = Std.parseFloat(result[2]) * scale;
      data[i++] = Std.parseFloat(result[3]) * scale;
      data[i++] = scale;
    }

    var texture3D = new Data3DTexture();
    texture3D.image.data = data;
    texture3D.image.width = size;
    texture3D.image.height = size;
    texture3D.image.depth = size;
    texture3D.type = type;
    texture3D.magFilter = LinearFilter;
    texture3D.minFilter = LinearFilter;
    texture3D.wrapS = ClampToEdgeWrapping;
    texture3D.wrapT = ClampToEdgeWrapping;
    texture3D.wrapR = ClampToEdgeWrapping;
    texture3D.generateMipmaps = false;
    texture3D.needsUpdate = true;

    return {title: title, size: size, domainMin: domainMin, domainMax: domainMax, texture3D: texture3D};
  }
}