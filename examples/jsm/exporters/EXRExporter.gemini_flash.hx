import three.FloatType;
import three.HalfFloatType;
import three.RGBAFormat;
import three.DataUtils;
import fflate.FFlate;
import haxe.io.Bytes;
import haxe.io.Output;

class EXRExporter {

	public static var NO_COMPRESSION:Int = 0;
	public static var ZIPS_COMPRESSION:Int = 2;
	public static var ZIP_COMPRESSION:Int = 3;

	public function new() {}

	public function parse(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Bytes {

		if (!arg1 || !(arg1.isWebGLRenderer || arg1.isDataTexture)) {
			throw "EXRExporter.parse: Unsupported first parameter, expected instance of WebGLRenderer or DataTexture.";
		}
		else if (arg1.isWebGLRenderer) {
			var renderer = cast arg1 : WebGLRenderer;
			var renderTarget = cast arg2 : WebGLRenderTarget;
			var options = cast arg3 : Dynamic;
			supportedRTT(renderTarget);
			var info = buildInfoRTT(renderTarget, options);
			var dataBuffer = getPixelData(renderer, renderTarget, info);
			var rawContentBuffer = reorganizeDataBuffer(dataBuffer, info);
			var chunks = compressData(rawContentBuffer, info);
			return fillData(chunks, info);
		}
		else if (arg1.isDataTexture) {
			var texture = cast arg1 : DataTexture;
			var options = cast arg2 : Dynamic;
			supportedDT(texture);
			var info = buildInfoDT(texture, options);
			var dataBuffer = texture.image.data;
			var rawContentBuffer = reorganizeDataBuffer(dataBuffer, info);
			var chunks = compressData(rawContentBuffer, info);
			return fillData(chunks, info);
		}
		return null;
	}

	private function supportedRTT(renderTarget:WebGLRenderTarget) {
		if (!renderTarget || !renderTarget.isWebGLRenderTarget) {
			throw "EXRExporter.parse: Unsupported second parameter, expected instance of WebGLRenderTarget.";
		}

		if (renderTarget.isWebGLCubeRenderTarget || renderTarget.isWebGL3DRenderTarget || renderTarget.isWebGLArrayRenderTarget) {
			throw "EXRExporter.parse: Unsupported render target type, expected instance of WebGLRenderTarget.";
		}

		if (renderTarget.texture.type != FloatType && renderTarget.texture.type != HalfFloatType) {
			throw "EXRExporter.parse: Unsupported WebGLRenderTarget texture type.";
		}

		if (renderTarget.texture.format != RGBAFormat) {
			throw "EXRExporter.parse: Unsupported WebGLRenderTarget texture format, expected RGBAFormat.";
		}
	}

	private function supportedDT(texture:DataTexture) {
		if (texture.type != FloatType && texture.type != HalfFloatType) {
			throw "EXRExporter.parse: Unsupported DataTexture texture type.";
		}

		if (texture.format != RGBAFormat) {
			throw "EXRExporter.parse: Unsupported DataTexture texture format, expected RGBAFormat.";
		}

		if (texture.image.data == null) {
			throw "EXRExporter.parse: Invalid DataTexture image data.";
		}

		if (texture.type == FloatType && texture.image.data.constructor.name != "Float32Array") {
			throw "EXRExporter.parse: DataTexture image data doesn't match type, expected 'Float32Array'.";
		}

		if (texture.type == HalfFloatType && texture.image.data.constructor.name != "Uint16Array") {
			throw "EXRExporter.parse: DataTexture image data doesn't match type, expected 'Uint16Array'.";
		}
	}

	private function buildInfoRTT(renderTarget:WebGLRenderTarget, options:Dynamic = {}):Dynamic {
		var compressionSizes = {
			0: 1,
			2: 1,
			3: 16
		};

		var WIDTH = renderTarget.width;
		var HEIGHT = renderTarget.height;
		var TYPE = renderTarget.texture.type;
		var FORMAT = renderTarget.texture.format;
		var COMPRESSION = (options.compression != null) ? options.compression : ZIP_COMPRESSION;
		var EXPORTER_TYPE = (options.type != null) ? options.type : HalfFloatType;
		var OUT_TYPE = (EXPORTER_TYPE == FloatType) ? 2 : 1;
		var COMPRESSION_SIZE = compressionSizes[COMPRESSION];
		var NUM_CHANNELS = 4;

		return {
			width: WIDTH,
			height: HEIGHT,
			type: TYPE,
			format: FORMAT,
			compression: COMPRESSION,
			blockLines: COMPRESSION_SIZE,
			dataType: OUT_TYPE,
			dataSize: 2 * OUT_TYPE,
			numBlocks: Math.ceil(HEIGHT / COMPRESSION_SIZE),
			numInputChannels: 4,
			numOutputChannels: NUM_CHANNELS,
		};
	}

	private function buildInfoDT(texture:DataTexture, options:Dynamic = {}):Dynamic {
		var compressionSizes = {
			0: 1,
			2: 1,
			3: 16
		};

		var WIDTH = texture.image.width;
		var HEIGHT = texture.image.height;
		var TYPE = texture.type;
		var FORMAT = texture.format;
		var COMPRESSION = (options.compression != null) ? options.compression : ZIP_COMPRESSION;
		var EXPORTER_TYPE = (options.type != null) ? options.type : HalfFloatType;
		var OUT_TYPE = (EXPORTER_TYPE == FloatType) ? 2 : 1;
		var COMPRESSION_SIZE = compressionSizes[COMPRESSION];
		var NUM_CHANNELS = 4;

		return {
			width: WIDTH,
			height: HEIGHT,
			type: TYPE,
			format: FORMAT,
			compression: COMPRESSION,
			blockLines: COMPRESSION_SIZE,
			dataType: OUT_TYPE,
			dataSize: 2 * OUT_TYPE,
			numBlocks: Math.ceil(HEIGHT / COMPRESSION_SIZE),
			numInputChannels: 4,
			numOutputChannels: NUM_CHANNELS,
		};
	}

	private function getPixelData(renderer:WebGLRenderer, rtt:WebGLRenderTarget, info:Dynamic):Array<Float> {
		var dataBuffer:Array<Float>;

		if (info.type == FloatType) {
			dataBuffer = new Array<Float>(info.width * info.height * info.numInputChannels);
		}
		else {
			dataBuffer = new Array<Float>(info.width * info.height * info.numInputChannels);
		}

		renderer.readRenderTargetPixels(rtt, 0, 0, info.width, info.height, dataBuffer);

		return dataBuffer;
	}

	private function reorganizeDataBuffer(inBuffer:Array<Float>, info:Dynamic):Bytes {
		var w = info.width;
		var h = info.height;
		var dec = { r: 0.0, g: 0.0, b: 0.0, a: 0.0 };
		var offset = { value: 0 };
		var cOffset = (info.numOutputChannels == 4) ? 1 : 0;
		var getValue = (info.type == FloatType) ? getFloat32 : getFloat16;
		var setValue = (info.dataType == 1) ? setFloat16 : setFloat32;
		var outBuffer = new Bytes(info.width * info.height * info.numOutputChannels * info.dataSize);
		var dv = new DataView(outBuffer.buffer);

		for (y in 0...h) {
			for (x in 0...w) {
				var i = y * w * 4 + x * 4;

				var r = getValue(inBuffer, i);
				var g = getValue(inBuffer, i + 1);
				var b = getValue(inBuffer, i + 2);
				var a = getValue(inBuffer, i + 3);

				var line = (h - y - 1) * w * (3 + cOffset) * info.dataSize;

				decodeLinear(dec, r, g, b, a);

				offset.value = line + x * info.dataSize;
				setValue(dv, dec.a, offset);

				offset.value = line + (cOffset) * w * info.dataSize + x * info.dataSize;
				setValue(dv, dec.b, offset);

				offset.value = line + (1 + cOffset) * w * info.dataSize + x * info.dataSize;
				setValue(dv, dec.g, offset);

				offset.value = line + (2 + cOffset) * w * info.dataSize + x * info.dataSize;
				setValue(dv, dec.r, offset);
			}
		}

		return outBuffer;
	}

	private function compressData(inBuffer:Bytes, info:Dynamic):{ data:Array<{ dataChunk:Bytes, size:Int }>, totalSize:Int } {
		var compress:Dynamic;
		var tmpBuffer:Bytes;
		var sum = 0;

		var chunks = { data: new Array(), totalSize: 0 };
		var size = info.width * info.numOutputChannels * info.blockLines * info.dataSize;

		switch (info.compression) {
			case 0:
				compress = compressNONE;
				break;
			case 2:
			case 3:
				compress = compressZIP;
				break;
		}

		if (info.compression != 0) {
			tmpBuffer = new Bytes(size);
		}

		for (i in 0...info.numBlocks) {
			var arr = inBuffer.sub(size * i, size * (i + 1));
			var block = compress(arr, tmpBuffer);
			sum += block.length;
			chunks.data.push({ dataChunk: block, size: block.length });
		}

		chunks.totalSize = sum;

		return chunks;
	}

	private function compressNONE(data:Bytes):Bytes {
		return data;
	}

	private function compressZIP(data:Bytes, tmpBuffer:Bytes):Bytes {
		// Reorder the pixel data.
		var t1 = 0;
		var t2 = Math.floor((data.length + 1) / 2);
		var s = 0;

		var stop = data.length - 1;

		while (true) {
			if (s > stop) break;
			tmpBuffer.set(t1++, data.get(s++));
			if (s > stop) break;
			tmpBuffer.set(t2++, data.get(s++));
		}

		// Predictor.
		var p = tmpBuffer.get(0);

		for (t in 1...tmpBuffer.length) {
			var d = tmpBuffer.get(t) - p + (128 + 256);
			p = tmpBuffer.get(t);
			tmpBuffer.set(t, d);
		}

		return FFlate.zlibSync(tmpBuffer);
	}

	private function fillHeader(outBuffer:Bytes, chunks:Dynamic, info:Dynamic) {
		var offset = { value: 0 };
		var dv = new DataView(outBuffer.buffer);
		setUint32(dv, 20000630, offset); // magic
		setUint32(dv, 2, offset); // mask

		// = HEADER =
		setString(dv, "compression", offset);
		setString(dv, "compression", offset);
		setUint32(dv, 1, offset);
		setUint8(dv, info.compression, offset);

		setString(dv, "screenWindowCenter", offset);
		setString(dv, "v2f", offset);
		setUint32(dv, 8, offset);
		setUint32(dv, 0, offset);
		setUint32(dv, 0, offset);

		setString(dv, "screenWindowWidth", offset);
		setString(dv, "float", offset);
		setUint32(dv, 4, offset);
		setFloat32(dv, 1.0, offset);

		setString(dv, "pixelAspectRatio", offset);
		setString(dv, "float", offset);
		setUint32(dv, 4, offset);
		setFloat32(dv, 1.0, offset);

		setString(dv, "lineOrder", offset);
		setString(dv, "lineOrder", offset);
		setUint32(dv, 1, offset);
		setUint8(dv, 0, offset);

		setString(dv, "dataWindow", offset);
		setString(dv, "box2i", offset);
		setUint32(dv, 16, offset);
		setUint32(dv, 0, offset);
		setUint32(dv, 0, offset);
		setUint32(dv, info.width - 1, offset);
		setUint32(dv, info.height - 1, offset);

		setString(dv, "displayWindow", offset);
		setString(dv, "box2i", offset);
		setUint32(dv, 16, offset);
		setUint32(dv, 0, offset);
		setUint32(dv, 0, offset);
		setUint32(dv, info.width - 1, offset);
		setUint32(dv, info.height - 1, offset);

		setString(dv, "channels", offset);
		setString(dv, "chlist", offset);
		setUint32(dv, info.numOutputChannels * 18 + 1, offset);

		setString(dv, "A", offset);
		setUint32(dv, info.dataType, offset);
		offset.value += 4;
		setUint32(dv, 1, offset);
		setUint32(dv, 1, offset);

		setString(dv, "B", offset);
		setUint32(dv, info.dataType, offset);
		offset.value += 4;
		setUint32(dv, 1, offset);
		setUint32(dv, 1, offset);

		setString(dv, "G", offset);
		setUint32(dv, info.dataType, offset);
		offset.value += 4;
		setUint32(dv, 1, offset);
		setUint32(dv, 1, offset);

		setString(dv, "R", offset);
		setUint32(dv, info.dataType, offset);
		offset.value += 4;
		setUint32(dv, 1, offset);
		setUint32(dv, 1, offset);

		setUint8(dv, 0, offset);

		// null-byte
		setUint8(dv, 0, offset);

		// = OFFSET TABLE =
		var sum = offset.value + info.numBlocks * 8;

		for (i in 0...chunks.data.length) {
			setUint64(dv, sum, offset);
			sum += chunks.data[i].size + 8;
		}
	}

	private function fillData(chunks:Dynamic, info:Dynamic):Bytes {
		var TableSize = info.numBlocks * 8;
		var HeaderSize = 259 + (18 * info.numOutputChannels); // 259 + 18 * chlist
		var offset = { value: HeaderSize + TableSize };
		var outBuffer = new Bytes(HeaderSize + TableSize + chunks.totalSize + info.numBlocks * 8);
		var dv = new DataView(outBuffer.buffer);

		fillHeader(outBuffer, chunks, info);

		for (i in 0...chunks.data.length) {
			var data = chunks.data[i].dataChunk;
			var size = chunks.data[i].size;

			setUint32(dv, i * info.blockLines, offset);
			setUint32(dv, size, offset);

			outBuffer.blit(offset.value, data, 0, size);
			offset.value += size;
		}

		return outBuffer;
	}

	private function decodeLinear(dec:Dynamic, r:Float, g:Float, b:Float, a:Float) {
		dec.r = r;
		dec.g = g;
		dec.b = b;
		dec.a = a;
	}

	// private function decodeSRGB(dec:Dynamic, r:Float, g:Float, b:Float, a:Float) {
	// 	dec.r = r > 0.04045 ? Math.pow(r * 0.9478672986 + 0.0521327014, 2.4) : r * 0.0773993808;
	// 	dec.g = g > 0.04045 ? Math.pow(g * 0.9478672986 + 0.0521327014, 2.4) : g * 0.0773993808;
	// 	dec.b = b > 0.04045 ? Math.pow(b * 0.9478672986 + 0.0521327014, 2.4) : b * 0.0773993808;
	// 	dec.a = a;
	// }

	private function setUint8(dv:DataView, value:Int, offset:Dynamic) {
		dv.setUint8(offset.value, value);
		offset.value += 1;
	}

	private function setUint32(dv:DataView, value:Int, offset:Dynamic) {
		dv.setUint32(offset.value, value, true);
		offset.value += 4;
	}

	private function setFloat16(dv:DataView, value:Float, offset:Dynamic) {
		dv.setUint16(offset.value, DataUtils.toHalfFloat(value), true);
		offset.value += 2;
	}

	private function setFloat32(dv:DataView, value:Float, offset:Dynamic) {
		dv.setFloat32(offset.value, value, true);
		offset.value += 4;
	}

	private function setUint64(dv:DataView, value:Int, offset:Dynamic) {
		dv.setBigUint64(offset.value, cast value : UInt64, true);
		offset.value += 8;
	}

	private function setString(dv:DataView, string:String, offset:Dynamic) {
		var tmp = haxe.io.Bytes.ofString(string + "\0");

		for (i in 0...tmp.length) {
			setUint8(dv, tmp.get(i), offset);
		}
	}

	private function decodeFloat16(binary:Int):Float {
		var exponent = (binary & 0x7C00) >> 10;
		var fraction = binary & 0x03FF;

		return (binary >> 15 ? -1 : 1) * (
			exponent ?
				(
					exponent == 0x1F ?
						fraction ? NaN : Infinity :
						Math.pow(2, exponent - 15) * (1 + fraction / 0x400)
				) :
				6.103515625e-5 * (fraction / 0x400)
		);
	}

	private function getFloat16(arr:Array<Float>, i:Int):Float {
		return decodeFloat16(cast arr[i] : Int);
	}

	private function getFloat32(arr:Array<Float>, i:Int):Float {
		return arr[i];
	}
}