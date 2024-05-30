package three.jsm.loaders;

import three.ClampToEdgeWrapping;
import three.Data3DTexture;
import three.FileLoader;
import three.FloatType;
import three.LinearFilter;
import three.Loader;
import three.UnsignedByteType;
import three.Vector3;

class LUTCubeLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
		this.type = UnsignedByteType;
	}

	public function setType(type:Int):LUTCubeLoader {
		if (type != UnsignedByteType && type != FloatType) {
			throw 'LUTCubeLoader: Unsupported type';
		}
		this.type = type;
		return this;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('text');
		loader.load(url, function(text:String) {
			try {
				onLoad(this.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(input:String):Dynamic {
		var regExpTitle = /TITLE +"([^"]*)"/;
		var regExpSize = /LUT_3D_SIZE +(\d+)/;
		var regExpDomainMin = /DOMAIN_MIN +([\d.]+) +([\d.]+) +([\d.]+)/;
		var regExpDomainMax = /DOMAIN_MAX +([\d.]+) +([\d.]+) +([\d.]+)/;
		var regExpDataPoints = /^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

		var result = regExpTitle.exec(input);
		var title = (result != null) ? result[1] : null;

		result = regExpSize.exec(input);
		if (result == null) {
			throw 'LUTCubeLoader: Missing LUT_3D_SIZE information';
		}
		var size = untyped __js__('Number')(result[1]);
		var length = size ** 3 * 4;
		var data = (this.type == UnsignedByteType) ? new Uint8Array(length) : new Float32Array(length);

		var domainMin = new Vector3(0, 0, 0);
		var domainMax = new Vector3(1, 1, 1);

		result = regExpDomainMin.exec(input);
		if (result != null) {
			domainMin.set(untyped __js__('Number')(result[1]), untyped __js__('Number')(result[2]), untyped __js__('Number')(result[3]));
		}

		result = regExpDomainMax.exec(input);
		if (result != null) {
			domainMax.set(untyped __js__('Number')(result[1]), untyped __js__('Number')(result[2]), untyped __js__('Number')(result[3]));
		}

		if (domainMin.x > domainMax.x || domainMin.y > domainMax.y || domainMin.z > domainMax.z) {
			throw 'LUTCubeLoader: Invalid input domain';
		}

		var scale = (this.type == UnsignedByteType) ? 255 : 1;
		var i = 0;

		while ((result = regExpDataPoints.exec(input)) != null) {
			data[i++] = untyped __js__('Number')(result[1]) * scale;
			data[i++] = untyped __js__('Number')(result[2]) * scale;
			data[i++] = untyped __js__('Number')(result[3]) * scale;
			data[i++] = scale;
		}

		var texture3D = new Data3DTexture();
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