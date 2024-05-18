import DataUtils from 'three/src/math/DataUtils';
import fflate from 'fflate';

class EXRExporter {

	public function parse(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):ArrayBuffer {
		if (!arg1 || !(Std.is(arg1, WebGLRenderer) || Std.is(arg1, DataTexture))) {
			throw Error('EXRExporter.parse: Unsupported first parameter, expected instance of WebGLRenderer or DataTexture.');
		} else if (Std.is(arg1, WebGLRenderer)) {
			var renderer = arg1;
			var renderTarget = arg2;
			var options = arg3;

			supportedRTT(renderTarget);

			var info = buildInfoRTT(renderTarget, options);
			var dataBuffer = getPixelData(renderer, renderTarget, info);
			var rawContentBuffer = reorganizeDataBuffer(dataBuffer, info);
			var chunks = compressData(rawContentBuffer, info);

			return fillData(chunks, info);
		} else if (Std.is(arg1, DataTexture)) {
			var texture = arg1;
			var options = arg2;

			supportedDT(texture);

			var info = buildInfoDT(texture, options);
			var dataBuffer = texture.image.data;
			var rawContentBuffer = reorganizeDataBuffer(dataBuffer, info);
			var chunks = compressData(rawContentBuffer, info);

			return fillData(chunks, info);
		}
	}

}

function supportedRTT(renderTarget:Dynamic) {
	if (!renderTarget || !Std.is(renderTarget, WebGLRenderTarget)) {
		throw Error('EXRExporter.parse: Unsupported second parameter, expected instance of WebGLRenderTarget.');
	}

	if (Std.is(renderTarget, WebGLCubeRenderTarget) || Std.is(renderTarget, WebGL3DRenderTarget) || Std.is(renderTarget, WebGLArrayRenderTarget)) {
		throw Error('EXRExporter.parse: Unsupported render target type, expected instance of WebGLRenderTarget.');
	}

	if (renderTarget.texture.type != FloatType && renderTarget.texture.type != HalfFloatType) {
		throw Error('EXRExporter.parse: Unsupported WebGLRenderTarget texture type.');
	}

	if (renderTarget.texture.format != RGBAFormat) {
		throw Error('EXRExporter.parse: Unsupported WebGLRenderTarget texture format, expected RGBAFormat.');
	}
}

function supportedDT(texture:Dynamic) {
	if (texture.type != FloatType && texture.type != HalfFloatType) {
		throw Error('EXRExporter.parse: Unsupported DataTexture texture type.');
	}

	if (texture.format != RGBAFormat) {
		throw Error('EXRExporter.parse: Unsupported DataTexture texture format, expected RGBAFormat.');
	}

	if (!texture.image.data) {
		throw Error('EXRExporter.parse: Invalid DataTexture image data.');
	}

	if (texture.type == FloatType && texture.image.data.constructor.name != 'Float32Array') {
		throw Error('EXRExporter.parse: DataTexture image data doesn\'t match type, expected \'Float32Array\'.');
	}

	if (texture.type == HalfFloatType && texture.image.data.constructor.name != 'Uint16Array') {
		throw Error('EXRExporter.parse: DataTexture image data doesn\'t match type, expected \'Uint16Array\'.');
	}
}

function buildInfoRTT(renderTarget:Dynamic, options:Dynamic = {}):Dynamic {
	var compressionSizes = {
		0: 1,
		2: 1,
		3: 16
	};

	var WIDTH = renderTarget.width;
	var HEIGHT = renderTarget.height;
	var TYPE = renderTarget.texture.type;
	var FORMAT = renderTarget.texture.format;
	var COMPRESSION = (options.compression != undefined) ? options.compression : ZIP_COMPRESSION;
	var EXPORTER_TYPE = (options.type != undefined) ? options.type : HalfFloatType;
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

function buildInfoDT(texture:Dynamic, options:Dynamic = {}):Dynamic {
	var compressionSizes = {
		0: 1,
		2: 1,
		3: 16
	};

	var WIDTH = texture.image.width;
	var HEIGHT = texture.image.height;
	var TYPE = texture.type;
	var FORMAT = texture.format;
	var COMPRESSION = (options.compression != undefined) ? options.compression : ZIP_COMPRESSION;
	var EXPORTER_TYPE = (options.type != undefined) ? options.type : HalfFloatType;
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

function getPixelData(renderer:Dynamic, rtt:Dynamic, info:Dynamic):ArrayBuffer {
	var dataBuffer;

	if (info.type == FloatType) {
		dataBuffer = new Float32Array(info.width * info.height * info.numInputChannels);
	} else {
		dataBuffer = new Int16Array(info.width * info.height * info.numInputChannels);
	}

	renderer.readRenderTargetPixels(rtt, 0, 0, info.width, info.height, dataBuffer);

	return dataBuffer.buffer;
}

function reorganizeDataBuffer(inBuffer:ArrayBuffer, info:Dynamic):ArrayBuffer {
	var w = info.width;
	var h = info.height;
	var dec = { r: 0, g: 0, b: 0, a: 0 };
	var offset = { value: 0 };
	var cOffset = (info.numOutputChannels == 4) ? 1 : 0;
	var getValue = (info.type == FloatType) ? getFloat32 : getFloat16;
	var setValue = (info.dataType == 1) ? setFloat16 : setFloat32;
	var outBuffer = new ArrayBuffer(info.width * info.height * info.numOutputChannels * info.dataSize);
	var dv = new DataView(outBuffer);

	for (var y = 0; y < h; ++y) {
		for (var x = 0; x < w; ++x) {
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

function compressData(inBuffer:ArrayBuffer, info:Dynamic):Array<Dynamic> {
	var compress:Dynamic;
	var tmpBuffer:ArrayBuffer;
	var sum = 0;

	var chunks = { data: new Array<Dynamic>(), totalSize: 0 };
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
		tmpBuffer = new ArrayBuffer(size);
	}

	for (var i = 0; i < info.numBlocks; ++i) {
		var arr = new Uint8Array(inBuffer, i * size, size);

		var block = compress(arr, tmpBuffer);

		sum += block.length;

		chunks.data.push({ dataChunk: block, size: block.length });
	}

	chunks.totalSize = sum;

	return chunks;
}

function compressNONE(data:ArrayBuffer):ArrayBuffer {
	return data;
}

function compressZIP(data:ArrayBuffer, tmpBuffer:ArrayBuffer):ArrayBuffer {
	//
	// Reorder the pixel data.
	//

	var t1 = 0;
	var t2 = Math.floor((data.length + 1) / 2);
	var s = 0;
	var stop = data.length - 1;

	while (true) {
		if (s > stop) break;
		(new Uint8Array(tmpBuffer)).set([new DataView(data).getUint8(s++)], t1++);

		if (s > stop) break;
		(new Uint8Array(tmpBuffer)).set([new DataView(data).getUint8(s++)], t2++);
	}

	//
	// Predictor.
	//

	var p = new DataView(tmpBuffer).getUint8(0);

	for (var t = 1; t < tmpBuffer.byteLength; t++) {
		var d = new DataView(tmpBuffer).getUint8(t) - p + (128 + 256);
		p = new DataView(tmpBuffer).getUint8(t);
		(new Uint8Array(tmpBuffer)).set([d], t);
	}

	var deflate = fflate.zlibSync((new Uint8Array(tmpBuffer)).buffer);

	return deflate;
}

function fillHeader(outBuffer:ArrayBuffer, chunks:Array<Dynamic>, info:Dynamic) {
	var offset = { value: 0 };
	var dv = new DataView(outBuffer);

	setUint32(dv, 20000630, offset); // magic
	setUint32(dv, 2, offset); // mask

	// = HEADER =

	setString(dv, 'compression', offset);
	setString(dv, 'compression', offset);
	setUint32(dv, 1, offset);
	setUint8(dv, info.compression, offset);

	setString(dv, 'screenWindowCenter', offset);
	setString(dv, 'v2f', offset);
	setUint32(dv, 8, offset);
	setUint32(dv, 0, offset);
	setUint32(dv, 0, offset);

	setString(dv, 'screenWindowWidth', offset);
	setString(dv, 'float', offset);
	setUint32(dv, 4, offset);
	setFloat32(dv, 1.0, offset);

	setString(dv, 'pixelAspectRatio', offset);
	setString(dv, 'float', offset);
	setUint32(dv, 4, offset);
	setFloat32(dv, 1.0, offset);

	setString(dv, 'lineOrder', offset);
	setString(dv, 'lineOrder', offset);
	setUint32(dv, 1, offset);
	setUint8(dv, 0, offset);

	setString(dv, 'dataWindow', offset);
	setString(dv, 'box2i', offset);
	setUint32(dv, 16, offset);
	setUint32(dv, 0, offset);
	setUint32(dv, 0, offset);
	setUint32(dv, info.width - 1, offset);
	setUint32(dv, info.height - 1, offset);

	setString(dv, 'displayWindow', offset);
	setString(dv, 'box2i', offset);
	setUint32(dv, 16, offset);
	setUint32(dv, 0, offset);
	setUint32(dv, 0, offset);
	setUint32(dv, info.width - 1, offset);
	setUint32(dv, info.height - 1, offset);

	setString(dv, 'channels', offset);
	setString(dv, 'chlist', offset);
	setUint32(dv, info.numOutputChannels * 18 + 1, offset);

	setString(dv, 'A', offset);
	setUint32(dv, info.dataType, offset);
	offset.value += 4;
	setUint32(dv, 1, offset);
	setUint32(dv, 1, offset);

	setString(dv, 'B', offset);
	setUint32(dv, info.dataType, offset);
	offset.value += 4;
	setUint32(dv, 1, offset);
	setUint32(dv, 1, offset);

	setString(dv, 'G', offset);
	setUint32(dv, info.dataType, offset);
	offset.value += 4;
	setUint32(dv, 1, offset);
	setUint32(dv, 1, offset);

	setString(dv, 'R', offset);
	setUint32(dv, info.dataType, offset);
	offset.value += 4;
	setUint32(dv, 1, offset);
	setUint32(dv, 1, offset);

	setUint8(dv, 0, offset);

	// null-byte
	setUint8(dv, 0, offset);

	// = OFFSET TABLE =

	var sum = offset.value + info.numBlocks * 8;

	for (var i = 0; i < chunks.data.length; ++i) {
		setUint64(dv, sum, offset);

		sum += chunks.data[i].size + 8;
	}
}

function fillData(chunks:Array<Dynamic>, info:Dynamic):ArrayBuffer {
	var TableSize = info.numBlocks * 8;
	var HeaderSize = 259 + (18 * info.numOutputChannels); // 259 + 18 * chlist
	var offset = { value: HeaderSize + TableSize };
	var outBuffer = new ArrayBuffer(HeaderSize + TableSize + chunks.totalSize + info.numBlocks * 8);
	var dv = new DataView(outBuffer);

	fillHeader(outBuffer, chunks, info);

	for (var i = 0; i < chunks.data.length; ++i) {
		var data = chunks.data[i].dataChunk;
		var size = chunks.data[i].size;

		setUint32(dv, i * info.blockLines, offset);
		setUint32(dv, size, offset);

		(new Uint8Array(outBuffer)).set(new Uint8Array(data), offset.value);
		offset.value += size;
	}

	return outBuffer;
}

function decodeLinear(dec:Dynamic, r:Float, g:Float, b:Float, a:Float) {
	dec.r = r;
	dec.g = g;
	dec.b = b;
	dec.a = a;
}

// function decodeSRGB(dec:Dynamic, r:Float, g:Float, b:Float, a:Float) {

// 	dec.r = r > 0.04045 ? Math.pow(r * 0.9478672986 + 0.0521327014, 2.4) : r * 0.0773993808;
// 	dec.g = g > 0.04045 ? Math.pow(g * 0.9478672986 + 0.0521327014, 2.4) : g * 0.0773993808;
// 	dec.b = b > 0.04045 ? Math.pow(b * 0.9478672986 + 0.0521327014, 2.4) : b * 0.0773993808;
// 	dec.a = a;

// }

function setUint8(dv:DataView, value:Int, offset:Dynamic) {
	dv.setUint8(offset.value, value);

	offset.value += 1;
}

function setUint32(dv:DataView, value:Int, offset:Dynamic) {
	dv.setUint32(offset.value, value, true);

	offset.value += 4;
}

function setFloat16(dv:DataView, value:Float, offset:Dynamic) {
	dv.setUint16(offset.value, DataUtils.toHalfFloat(value), true);

	offset.value += 2;
}

function setFloat32(dv:DataView, value:Float, offset:Dynamic) {
	dv.setFloat32(offset.value, value, true);

	offset.value += 4;
}

function setUint64(dv:DataView, value:Int, offset:Dynamic) {
	dv.setBigUint64(offset.value, BigInt(value), true);

	offset.value += 8;
}

function setString(dv:DataView, string:String, offset:Dynamic) {
	var tmp = Text.encode(string + '\0');

	for (var i = 0; i < tmp.length; ++i) {
		setUint8(dv, tmp[i], offset);
	}
}

function decodeFloat16(binary:Int) {
	var exponent = (binary & 0x7C00) >> 10,
		fraction = binary & 0x03FF;

	return (binary >> 15 ? -1 : 1) * (
		exponent ?
			(
				exponent === 0x1F ?
					fraction ? NaN : Infinity :
					Math.pow(2, exponent - 15) * (1 + fraction / 0x400)
			) :
			6.103515625e-5 * (fraction / 0x400)
	);
}

function getFloat16(arr:ArrayBuffer, i:Int) {
	return decodeFloat16(arr[i]);
}

function getFloat32(arr:ArrayBuffer, i:Int) {
	return arr[i];
}

}

const NO_COMPRESSION = 0;
const ZIP_COMPRESSION = 3;
const ZIPS_COMPRESSION = 2;