package three.js.examples.jsm.exporters;

import three.types.FloatType;
import three.types.HalfFloatType;
import three.formats.RGBAFormat;
import three.utils.DataUtils;
import fflate.Fflate;

class EXRExporter {
    public function new() {}

    public function parse(arg1:Dynamic, arg2:Dynamic, arg3:Dynamic):Bytes {
        if (!arg1 || !(arg1.isWebGLRenderer || arg1.isDataTexture)) {
            throw new Error('EXRExporter.parse: Unsupported first parameter, expected instance of WebGLRenderer or DataTexture.');
        } else if (arg1.isWebGLRenderer) {
            var renderer:WebGLRenderer = arg1;
            var renderTarget:WebGLRenderTarget = arg2;
            var options:Dynamic = arg3;
            supportedRTT(renderTarget);
            var info:Dynamic = buildInfoRTT(renderTarget, options);
            var dataBuffer:Array<Float> = getPixelData(renderer, renderTarget, info);
            var rawContentBuffer:Array<UInt8> = reorganizeDataBuffer(dataBuffer, info);
            var chunks:Array<Dynamic> = compressData(rawContentBuffer, info);
            return fillData(chunks, info);
        } else if (arg1.isDataTexture) {
            var texture:DataTexture = arg1;
            var options:Dynamic = arg2;
            supportedDT(texture);
            var info:Dynamic = buildInfoDT(texture, options);
            var dataBuffer:Array<Float> = texture.image.data;
            var rawContentBuffer:Array<UInt8> = reorganizeDataBuffer(dataBuffer, info);
            var chunks:Array<Dynamic> = compressData(rawContentBuffer, info);
            return fillData(chunks, info);
        }
        return null;
    }

    private function supportedRTT(renderTarget:WebGLRenderTarget):Void {
        if (!renderTarget || !renderTarget.isWebGLRenderTarget) {
            throw new Error('EXRExporter.parse: Unsupported second parameter, expected instance of WebGLRenderTarget.');
        }
        if (renderTarget.isWebGLCubeRenderTarget || renderTarget.isWebGL3DRenderTarget || renderTarget.isWebGLArrayRenderTarget) {
            throw new Error('EXRExporter.parse: Unsupported render target type, expected instance of WebGLRenderTarget.');
        }
        if (renderTarget.texture.type != FloatType && renderTarget.texture.type != HalfFloatType) {
            throw new Error('EXRExporter.parse: Unsupported WebGLRenderTarget texture type.');
        }
        if (renderTarget.texture.format != RGBAFormat) {
            throw new Error('EXRExporter.parse: Unsupported WebGLRenderTarget texture format, expected RGBAFormat.');
        }
    }

    private function supportedDT(texture:DataTexture):Void {
        if (texture.type != FloatType && texture.type != HalfFloatType) {
            throw new Error('EXRExporter.parse: Unsupported DataTexture texture type.');
        }
        if (texture.format != RGBAFormat) {
            throw new Error('EXRExporter.parse: Unsupported DataTexture texture format, expected RGBAFormat.');
        }
        if (texture.image.data == null) {
            throw new Error('EXRExporter.parse: Invalid DataTexture image data.');
        }
        if (texture.type == FloatType && !Std.isOfType(texture.image.data, Float32Array)) {
            throw new Error('EXRExporter.parse: DataTexture image data doesn\'t match type, expected \'Float32Array\'.');
        }
        if (texture.type == HalfFloatType && !Std.isOfType(texture.image.data, Uint16Array)) {
            throw new Error('EXRExporter.parse: DataTexture image data doesn\'t match type, expected \'Uint16Array\'.');
        }
    }

    private function buildInfoRTT(renderTarget:WebGLRenderTarget, options:Dynamic = {}):Dynamic {
        var compressionSizes:Dynamic = { 0: 1, 2: 1, 3: 16 };
        var WIDTH:Int = renderTarget.width;
        var HEIGHT:Int = renderTarget.height;
        var TYPE:Dynamic = renderTarget.texture.type;
        var FORMAT:Dynamic = renderTarget.texture.format;
        var COMPRESSION:Int = options.compression != null ? options.compression : 3;
        var EXPORTER_TYPE:Dynamic = options.type != null ? options.type : HalfFloatType;
        var OUT_TYPE:Int = EXPORTER_TYPE == FloatType ? 2 : 1;
        var COMPRESSION_SIZE:Int = compressionSizes[COMPRESSION];
        var NUM_CHANNELS:Int = 4;
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
            numOutputChannels: NUM_CHANNELS
        };
    }

    private function buildInfoDT(texture:DataTexture, options:Dynamic = {}):Dynamic {
        var compressionSizes:Dynamic = { 0: 1, 2: 1, 3: 16 };
        var WIDTH:Int = texture.image.width;
        var HEIGHT:Int = texture.image.height;
        var TYPE:Dynamic = texture.type;
        var FORMAT:Dynamic = texture.format;
        var COMPRESSION:Int = options.compression != null ? options.compression : 3;
        var EXPORTER_TYPE:Dynamic = options.type != null ? options.type : HalfFloatType;
        var OUT_TYPE:Int = EXPORTER_TYPE == FloatType ? 2 : 1;
        var COMPRESSION_SIZE:Int = compressionSizes[COMPRESSION];
        var NUM_CHANNELS:Int = 4;
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
            numOutputChannels: NUM_CHANNELS
        };
    }

    private function getPixelData(renderer:WebGLRenderer, rtt:WebGLRenderTarget, info:Dynamic):Array<Float> {
        var dataBuffer:Array<Float>;
        if (info.type == FloatType) {
            dataBuffer = new Array<Float>(info.width * info.height * info.numInputChannels);
        } else {
            dataBuffer = new Array<Float>(info.width * info.height * info.numInputChannels);
        }
        renderer.readRenderTargetPixels(rtt, 0, 0, info.width, info.height, dataBuffer);
        return dataBuffer;
    }

    private function reorganizeDataBuffer(inBuffer:Array<Float>, info:Dynamic):Array<UInt8> {
        var w:Int = info.width;
        var h:Int = info.height;
        var dec:Dynamic = { r: 0, g: 0, b: 0, a: 0 };
        var offset:Dynamic = { value: 0 };
        var cOffset:Int = info.numOutputChannels == 4 ? 1 : 0;
        var getValue:Float -> Float = info.type == FloatType ? function(f:Float) return f : function(f:Float) return decodeFloat16(f);
        var setValue:Void -> Void = info.dataType == 1 ? function(dv:BytesData, v:Float, o:Dynamic) dv.setUint16(o.value, Std.int(v * 0x10000), true) : function(dv:BytesData, v:Float, o:Dynamic) dv.setFloat32(o.value, v, true);
        var outBuffer:Array<UInt8> = new Array<UInt8>(info.width * info.height * info.numOutputChannels * info.dataSize);
        var dv:BytesData = new BytesData(outBuffer.length);
        for (y in 0...h) {
            for (x in 0...w) {
                var i:Int = y * w * 4 + x * 4;
                var r:Float = getValue(inBuffer[i]);
                var g:Float = getValue(inBuffer[i + 1]);
                var b:Float = getValue(inBuffer[i + 2]);
                var a:Float = getValue(inBuffer[i + 3]);
                decodeLinear(dec, r, g, b, a);
                offset.value = (h - y - 1) * w * (3 + cOffset) * info.dataSize + x * info.dataSize;
                setValue(dv, dec.a, offset);
                offset.value = (h - y - 1) * w * (3 + cOffset) * info.dataSize + (cOffset) * w * info.dataSize + x * info.dataSize;
                setValue(dv, dec.b, offset);
                offset.value = (h - y - 1) * w * (3 + cOffset) * info.dataSize + (1 + cOffset) * w * info.dataSize + x * info.dataSize;
                setValue(dv, dec.g, offset);
                offset.value = (h - y - 1) * w * (3 + cOffset) * info.dataSize + (2 + cOffset) * w * info.dataSize + x * info.dataSize;
                setValue(dv, dec.r, offset);
            }
        }
        return outBuffer;
    }

    private function compressData(inBuffer:Array<UInt8>, info:Dynamic):Array<Dynamic> {
        var compress:Dynamic;
        var tmpBuffer:Array<UInt8>;
        var sum:Int = 0;
        var chunks:Array<Dynamic> = { data: new Array<Dynamic>(), totalSize: 0 };
        var size:Int = info.width * info.numOutputChannels * info.blockLines * info.dataSize;
        switch (info.compression) {
            case 0:
                compress = compressNONE;
            case 2, 3:
                compress = compressZIP;
        }
        if (info.compression != 0) {
            tmpBuffer = new Array<UInt8>(size);
        }
        for (i in 0...info.numBlocks) {
            var arr:Array<UInt8> = inBuffer.subarray(size * i, size * (i + 1));
            var block:Array<UInt8> = compress(arr, tmpBuffer);
            sum += block.length;
            chunks.data.push({ dataChunk: block, size: block.length });
        }
        chunks.totalSize = sum;
        return chunks;
    }

    private function compressNONE(data:Array<UInt8>):Array<UInt8> {
        return data;
    }

    private function compressZIP(data:Array<UInt8>, tmpBuffer:Array<UInt8>):Array<UInt8> {
        var t1:Int = 0, t2:Int = Math.floor((data.length + 1) / 2);
        var s:Int = 0;
        var stop:Int = data.length - 1;
        while (true) {
            if (s > stop) break;
            tmpBuffer[t1++] = data[s++];
            if (s > stop) break;
            tmpBuffer[t2++] = data[s++];
        }
        var p:Int = tmpBuffer[0];
        for (t in 1...tmpBuffer.length) {
            var d:Int = tmpBuffer[t] - p + 128 + 256;
            p = tmpBuffer[t];
            tmpBuffer[t] = d;
        }
        var deflate:Array<UInt8> = fflate.zip(tmpBuffer);
        return deflate;
    }

    private function fillData(chunks:Array<Dynamic>, info:Dynamic):Bytes {
        var TableSize:Int = info.numBlocks * 8;
        var HeaderSize:Int = 259 + (18 * info.numOutputChannels);
        var offset:Dynamic = { value: HeaderSize + TableSize };
        var outBuffer:Array<UInt8> = new Array<UInt8>(HeaderSize + TableSize + chunks.totalSize + info.numBlocks * 8);
        var dv:BytesData = new BytesData(outBuffer.length);
        fillHeader(outBuffer, chunks, info);
        for (i in 0...chunks.data.length) {
            var data:Array<UInt8> = chunks.data[i].dataChunk;
            var size:Int = chunks.data[i].size;
            dv.setUint32(offset.value, i * info.blockLines);
            dv.setUint32(offset.value + 4, size);
            outBuffer.set(data, offset.value + 8);
            offset.value += size;
        }
        return Bytes.ofData(outBuffer);
    }

    private function fillHeader(outBuffer:Array<UInt8>, chunks:Array<Dynamic>, info:Dynamic):Void {
        var offset:Dynamic = { value: 0 };
        var dv:BytesData = new BytesData(outBuffer.length);
        dv.setUint32(offset.value, 20000630); // magic
        dv.setUint32(offset.value + 4, 2); // mask
        // = HEADER =
        setText(dv, 'compression', offset);
        setText(dv, 'compression', offset);
        dv.setUint32(offset.value, 1);
        dv.setUint8(offset.value + 4, info.compression);
        setText(dv, 'screenWindowCenter', offset);
        setText(dv, 'v2f', offset);
        dv.setUint32(offset.value, 8);
        dv.setUint32(offset.value + 4, 0);
        dv.setUint32(offset.value + 8, 0);
        setText(dv, 'screenWindowWidth', offset);
        setText(dv, 'float', offset);
        dv.setUint32(offset.value, 4);
        dv.setFloat32(offset.value + 4, 1.0);
        setText(dv, 'pixelAspectRatio', offset);
        setText(dv, 'float', offset);
        dv.setUint32(offset.value, 4);
        dv.setFloat32(offset.value + 4, 1.0);
        setText(dv, 'lineOrder', offset);
        setText(dv, 'lineOrder', offset);
        dv.setUint32(offset.value, 1);
        dv.setUint8(offset.value + 4, 0);
        setText(dv, 'dataWindow', offset);
        setText(dv, 'box2i', offset);
        dv.setUint32(offset.value, 16);
        dv.setUint32(offset.value + 4, 0);
        dv.setUint32(offset.value + 8, 0);
        dv.setUint32(offset.value + 12, info.width - 1);
        dv.setUint32(offset.value + 16, info.height - 1);
        setText(dv, 'displayWindow', offset);
        setText(dv, 'box2i', offset);
        dv.setUint32(offset.value, 16);
        dv.setUint32(offset.value + 4, 0);
        dv.setUint32(offset.value + 8, 0);
        dv.setUint32(offset.value + 12, info.width - 1);
        dv.setUint32(offset.value + 16, info.height - 1);
        setText(dv, 'channels', offset);
        setText(dv, 'chlist', offset);
        dv.setUint32(offset.value, info.numOutputChannels * 18 + 1);
        setText(dv, 'A', offset);
        dv.setUint32(offset.value, info.dataType);
        offset.value += 4;
        dv.setUint32(offset.value, 1);
        dv.setUint32(offset.value + 4, 1);
        setText(dv, 'B', offset);
        dv.setUint32(offset.value, info.dataType);
        offset.value += 4;
        dv.setUint32(offset.value, 1);
        dv.setUint32(offset.value + 4, 1);
        setText(dv, 'G', offset);
        dv.setUint32(offset.value, info.dataType);
        offset.value += 4;
        dv.setUint32(offset.value, 1);
        dv.setUint32(offset.value + 4, 1);
        setText(dv, 'R', offset);
        dv.setUint32(offset.value, info.dataType);
        offset.value += 4;
        dv.setUint32(offset.value, 1);
        dv.setUint32(offset.value + 4, 1);
        dv.setUint8(offset.value, 0);
        dv.setUint8(offset.value + 1, 0);
    }

    private function decodeLinear(dec:Dynamic, r:Float, g:Float, b:Float, a:Float):Void {
        dec.r = r;
        dec.g = g;
        dec.b = b;
        dec.a = a;
    }

    private function decodeFloat16(binary:Float):Float {
        var exponent:Int = (binary & 0x7C00) >> 10,
            fraction:Int = binary & 0x03FF;
        return (binary >> 15 ? -1 : 1) *
            (exponent ?
                (exponent === 0x1F ?
                    fraction ? Math.NaN : Math.POSITIVE_INFINITY :
                    Math.pow(2, exponent - 15) * (1 + fraction / 0x400)
                ) :
                6.103515625e-5 * (fraction / 0x400)
            );
    }

    private function getFloat16(arr:Array<Float>, i:Int):Float {
        return decodeFloat16(arr[i]);
    }

    private function getFloat32(arr:Array<Float>, i:Int):Float {
        return arr[i];
    }

    private function setUint8(dv:BytesData, value:Int, offset:Dynamic):Void {
        dv.setUint8(offset.value, value);
        offset.value++;
    }

    private function setUint32(dv:BytesData, value:Int, offset:Dynamic):Void {
        dv.setUint32(offset.value, value, true);
        offset.value += 4;
    }

    private function setFloat32(dv:BytesData, value:Float, offset:Dynamic):Void {
        dv.setFloat32(offset.value, value, true);
        offset.value += 4;
    }

    private function setText(dv:BytesData, string:String, offset:Dynamic):Void {
        var tmp:Array<UInt8> = Utf8.encode(string + '\0');
        for (i in 0...tmp.length) {
            setUint8(dv, tmp[i], offset);
        }
    }
}