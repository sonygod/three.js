// http://download.autodesk.com/us/systemdocs/help/2011/lustre/index.html?url=./files/WSc4e151a45a3b785a24c3d9a411df9298473-7ffd.htm,topicNumber=d0e9492
// https://community.foundry.com/discuss/topic/103636/format-spec-for-3dl?mode=Post&postID=895258

import three.examples.jsm.loaders.ClampToEdgeWrapping;
import three.examples.jsm.loaders.Data3DTexture;
import three.examples.jsm.loaders.FileLoader;
import three.examples.jsm.loaders.FloatType;
import three.examples.jsm.loaders.LinearFilter;
import three.examples.jsm.loaders.Loader;
import three.examples.jsm.loaders.RGBAFormat;
import three.examples.jsm.loaders.UnsignedByteType;

class LUT3dlLoader extends Loader {

	public var type:UnsignedByteType;

	public function new(manager:LoaderManager) {
		super(manager);
		this.type = UnsignedByteType;
	}

	public function setType(type:UnsignedByteType):LUT3dlLoader {
		if (type != UnsignedByteType && type != FloatType) {
			throw new Error("LUT3dlLoader: Unsupported type");
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
			} catch (e:Error) {
				if (onError != null) {
					onError(e);
				} else {
					Sys.println(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(input:String) {
		var regExpGridInfo:EReg = ~/^[\d ]+$/m;
		var regExpDataPoints:EReg = ~/^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

		// The first line describes the positions of values on the LUT grid.
		var result:Array<String> = regExpGridInfo.match(input);

		if (result == null) {
			throw new Error("LUT3dlLoader: Missing grid information");
		}

		var gridLines:Array<Int> = result[0].trim().split(/\s+/g).map(function(x:String) return Std.parseInt(x));
		var gridStep:Int = gridLines[1] - gridLines[0];
		var size:Int = gridLines.length;
		var sizeSq:Int = size * size;

		for (i in 1...gridLines.length) {
			if (gridStep != (gridLines[i] - gridLines[i - 1])) {
				throw new Error("LUT3dlLoader: Inconsistent grid size");
			}
		}

		var dataFloat:Float32Array = new Float32Array(size * size * size * 4);
		var maxValue:Float = 0.0;
		var index:Int = 0;

		while (regExpDataPoints.match(input)) {
			var r:Float = Std.parseFloat(regExpDataPoints.matched(1));
			var g:Float = Std.parseFloat(regExpDataPoints.matched(2));
			var b:Float = Std.parseFloat(regExpDataPoints.matched(3));

			maxValue = Math.max(maxValue, r, g, b);

			var bLayer:Int = index % size;
			var gLayer:Int = Math.floor(index / size) % size;
			var rLayer:Int = Math.floor(index / (sizeSq)) % size;

			// b grows first, then g, then r.
			var d4:Int = (bLayer * sizeSq + gLayer * size + rLayer) * 4;
			dataFloat[d4] = r;
			dataFloat[d4 + 1] = g;
			dataFloat[d4 + 2] = b;

			index++;
		}

		// Determine the bit depth to scale the values to [0.0, 1.0].
		var bits:Int = Math.ceil(Math.log2(maxValue));
		var maxBitValue:Float = Math.pow(2, bits);

		var data:Dynamic;
		if (this.type == UnsignedByteType) {
			data = new Uint8Array(dataFloat.length);
		} else {
			data = dataFloat;
		}
		var scale:Float = this.type == UnsignedByteType ? 255 : 1;

		for (i in 0...data.length) {
			var i1:Int = i + 1;
			var i2:Int = i + 2;
			var i3:Int = i + 3;

			// Note: data is dataFloat when type is FloatType.
			data[i] = dataFloat[i] / maxBitValue * scale;
			data[i1] = dataFloat[i1] / maxBitValue * scale;
			data[i2] = dataFloat[i2] / maxBitValue * scale;
			data[i3] = scale;
		}

		var texture3D:Data3DTexture = new Data3DTexture();
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
			size,
			texture3D,
		};
	}
}