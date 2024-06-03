import three.extras.loaders.Loader;
import three.extras.loaders.FileLoader;
import three.textures.Data3DTexture;
import three.math.Vector3;
import three.constants.WrappingModes;
import three.constants.TextureFilter;
import three.constants.TextureDataType;

class LUTCubeLoader extends Loader {
  public var type:TextureDataType;

  public function new(manager:Loader = null) {
    super(manager);
    type = TextureDataType.UnsignedByte;
  }

  public function setType(type:TextureDataType) {
    if (type != TextureDataType.UnsignedByte && type != TextureDataType.Float) {
      throw new Error("LUTCubeLoader: Unsupported type");
    }
    this.type = type;
    return this;
  }

  public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null) {
    var loader = new FileLoader(manager);
    loader.setPath(path);
    loader.setResponseType(FileLoader.ResponseTypes.TEXT);
    loader.load(url, function(text:String) {
      try {
        onLoad(parse(text));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          Sys.println(e);
        }
        manager.itemError(url);
      }
    }, onProgress, onError);
  }

  public function parse(input:String):Dynamic {
    var regExpTitle = ~/TITLE +"([^"]*)"/;
    var regExpSize = ~/LUT_3D_SIZE +(\d+)/;
    var regExpDomainMin = ~/DOMAIN_MIN +([\d.]+) +([\d.]+) +([\d.]+)/;
    var regExpDomainMax = ~/DOMAIN_MAX +([\d.]+) +([\d.]+) +([\d.]+)/;
    var regExpDataPoints = ~/^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

    var result = regExpTitle.exec(input);
    var title:String = (result != null) ? result[1] : null;

    result = regExpSize.exec(input);

    if (result == null) {
      throw new Error("LUTCubeLoader: Missing LUT_3D_SIZE information");
    }

    var size:Int = Std.parseInt(result[1]);
    var length:Int = Math.pow(size, 3) * 4;
    var data:Array<Float> = (type == TextureDataType.UnsignedByte) ? new Uint8Array(length) : new Float32Array(length);

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

    var scale = (type == TextureDataType.UnsignedByte) ? 255 : 1;
    var i = 0;

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
    texture3D.magFilter = TextureFilter.Linear;
    texture3D.minFilter = TextureFilter.Linear;
    texture3D.wrapS = WrappingModes.ClampToEdge;
    texture3D.wrapT = WrappingModes.ClampToEdge;
    texture3D.wrapR = WrappingModes.ClampToEdge;
    texture3D.generateMipmaps = false;
    texture3D.needsUpdate = true;

    return {
      title: title,
      size: size,
      domainMin: domainMin,
      domainMax: domainMax,
      texture3D: texture3D,
    };
  }
}