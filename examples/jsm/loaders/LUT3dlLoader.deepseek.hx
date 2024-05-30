import three.ClampToEdgeWrapping;
import three.Data3DTexture;
import three.FileLoader;
import three.FloatType;
import three.LinearFilter;
import three.Loader;
import three.RGBAFormat;
import three.UnsignedByteType;

class LUT3dlLoader extends Loader {

	public function new(manager:LoaderManager) {
		super(manager);
		this.type = UnsignedByteType;
	}

	public function setType(type:int):LUT3dlLoader {
		if (type != UnsignedByteType && type != FloatType) {
			throw 'LUT3dlLoader: Unsupported type';
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
		var regExpGridInfo = /^[\d ]+$/m;
		var regExpDataPoints = /^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

		var result = regExpGridInfo.exec(input);
		if (result == null) {
			throw 'LUT3dlLoader: Missing grid information';
		}

		var gridLines = result[0].trim().split(/\s+/g).map(function(s:String) return Std.parseInt(s));
		var gridStep = gridLines[1] - gridLines[0];
		var size = gridLines.length;
		var sizeSq = size * size;

		for (i in 1...gridLines.length) {
			if (gridStep != (gridLines[i] - gridLines[i - 1])) {
				throw 'LUT3dlLoader: Inconsistent grid size';
			}
		}

		var dataFloat = new Float32Array(size * size * size * 4);
		var maxValue = 0.0;
		var index = 0;

		while ((result = regExpDataPoints.exec(input)) != null) {
			var r = Std.parseFloat(result[1]);
			var g = Std.parseFloat(result[2]);
			var b = Std.parseFloat(result[3]);

			maxValue = Math.max(maxValue, r, g, b);

			var bLayer = index % size;
			var gLayer = Math.floor(index / size) % size;
			var rLayer = Math.floor(index / (sizeSq)) % size;

			var d4 = (bLayer * sizeSq + gLayer * size + rLayer) * 4;
			dataFloat[d4 + 0] = r;
			dataFloat[d4 + 1] = g;
			dataFloat[d4 + 2] = b;

			++index;
		}

		var bits = Math.ceil(Math.log2(maxValue));
		var maxBitValue = Math.pow(2, bits);

		var data = this.type == UnsignedByteType ? new Uint8Array(dataFloat.length) : dataFloat;
		var scale = this.type == UnsignedByteType ? 255 : 1;

		for (i in 0...data.length) {
			if (i % 4 == 0) {
				var i1 = i + 1;
				var i2 = i + 2;
				var i3 = i + 3;

				data[i] = dataFloat[i] / maxBitValue * scale;
				data[i1] = dataFloat[i1] / maxBitValue * scale;
				data[i2] = dataFloat[i2] / maxBitValue * scale;
				data[i3] = scale;
			}
		}

		var texture3D = new Data3DTexture();
		texture3D.image.data = data;
		texture3D.image.width = size;
		texture3D.image.height = size;
		texture3D.image.depth = size;
		texture3D.format = RGBAFormat;
		texture3D.type = this.type;
		texture3D.magFilter = LinearFilter;
		texture3D.minFilter = LinearFilter;
		texture3D.wrapS = ClampToEdgeWrapping;
		texture3D.wrapT = ClampToEdgeWrapping;
		texture3D.wrapR = ClampToEdgeWrapping;
		texture3D.generateMipmaps = false;
		texture3D.needsUpdate = true;

		return {
			size: size,
			texture3D: texture3D,
		};
	}
}