// https://wwwimages2.adobe.com/content/dam/acom/en/products/speedgrade/cc/pdfs/cube-lut-specification-1.0.pdf

import three.examples.jsm.loaders.ClampToEdgeWrapping;
import three.examples.jsm.loaders.Data3DTexture;
import three.examples.jsm.loaders.FileLoader;
import three.examples.jsm.loaders.FloatType;
import three.examples.jsm.loaders.LinearFilter;
import three.examples.jsm.loaders.Loader;
import three.examples.jsm.loaders.UnsignedByteType;
import three.examples.jsm.loaders.Vector3;

class LUTCubeLoader extends Loader {

	public var type:UnsignedByteType;

	public function new(manager:Loader.Manager) {
		super(manager);
		this.type = UnsignedByteType;
	}

	public function setType(type:UnsignedByteType):LUTCubeLoader {
		if (type !== UnsignedByteType && type !== FloatType) {
			throw new Error("LUTCubeLoader: Unsupported type");
		}
		this.type = type;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		var loader:FileLoader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType("text");
		loader.load(url, function(text:String) {
			try {
				onLoad(this.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Sys.println(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(input:String):Dynamic {
		var regExpTitle:RegExp = ~/TITLE +"([^"]*)"/;
		var regExpSize:RegExp = ~/LUT_3D_SIZE +(\d+)/;
		var regExpDomainMin:RegExp = ~/DOMAIN_MIN +([\d.]+) +([\d.]+) +([\d.]+)/;
		var regExpDomainMax:RegExp = ~/DOMAIN_MAX +([\d.]+) +([\d.]+) +([\d.]+)/;
		var regExpDataPoints:RegExp = ~/^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

		var result:Array<Dynamic> = regExpTitle.match(input);
		var title:String = (result != null) ? result[1] : null;

		result = regExpSize.match(input);

		if (result == null) {
			throw new Error("LUTCubeLoader: Missing LUT_3D_SIZE information");
		}

		var size:Int = Std.parseInt(result[1]);
		var length:Int = size ** 3 * 4;
		var data:Array<Float> = this.type == UnsignedByteType ? new Uint8Array(length) : new Float32Array(length);

		var domainMin:Vector3 = new Vector3(0, 0, 0);
		var domainMax:Vector3 = new Vector3(1, 1, 1);

		result = regExpDomainMin.match(input);

		if (result != null) {
			domainMin.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
		}

		result = regExpDomainMax.match(input);

		if (result != null) {
			domainMax.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
		}

		if (domainMin.x > domainMax.x || domainMin.y > domainMax.y || domainMin.z > domainMax.z) {
			throw new Error("LUTCubeLoader: Invalid input domain");
		}

		var scale:Float = this.type == UnsignedByteType ? 255 : 1;
		var i:Int = 0;

		while ((result = regExpDataPoints.match(input)) != null) {
			data[i++] = Std.parseFloat(result[1]) * scale;
			data[i++] = Std.parseFloat(result[2]) * scale;
			data[i++] = Std.parseFloat(result[3]) * scale;
			data[i++] = scale;
		}

		var texture3D:Data3DTexture = new Data3DTexture();
		texture3D.image.data = data;
		texture3D.image.width = size;
		texture3D.image.height = size;
		texture3D.image.depth = size;
		texture3D.type = this.type;
		texture3D.magFilter = LinearFilter;
		texture3D.minFilter = LinearFilter;
		texture3D.wrapS = ClampToEdgeWrapping;
		texture3D.wrapT = ClampToEdgeWrapping;
		texture3D.wrapR = ClampToEdgeWrapping;
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