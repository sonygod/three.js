package three.js.examples.jsm.loaders;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Float32Array;
import haxe.io.UInt8Array;
import three.Data3DTexture;
import three.FloatType;
import three.Loader;
import three.RgbaFormat;
import three.UnsignedByteType;
import three.wrapping.ClampToEdgeWrapping;
import three.wrapping.LinearFilter;

class LUT3dlLoader extends Loader {
    public var type:three.Type;

    public function new(manager:Loader) {
        super(manager);
        this.type = UnsignedByteType;
    }

    public function setType(type:three.Type):LUT3dlLoader {
        if (type != UnsignedByteType && type != FloatType) {
            throw new Error('LUT3dlLoader: Unsupported type');
        }
        this.type = type;
        return this;
    }

    public function load(url:String, onLoad:(result:Any) -> Void, onProgress:(progress:Int) -> Void, onError:(error:Error) -> Void):Void {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('text');
        loader.load(url, function(text:String) {
            try {
                onLoad(parse(text));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(input:String):{ size:Int, texture3D:Data3DTexture } {
        var regExpGridInfo = ~/^[\d ]+$/m;
        var regExpDataPoints = ~/^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

        // The first line describes the positions of values on the LUT grid.
        var result = regExpGridInfo.exec(input);

        if (result == null) {
            throw new Error('LUT3dlLoader: Missing grid information');
        }

        var gridLines:Array<Float> = result[0].trim().split~/\s+/.map(Std.parseFloat);
        var gridStep = gridLines[1] - gridLines[0];
        var size = gridLines.length;
        var sizeSq = size * size;

        for (i in 1...gridLines.length) {
            if (gridStep != gridLines[i] - gridLines[i - 1]) {
                throw new Error('LUT3dlLoader: Inconsistent grid size');
            }
        }

        var dataFloat:Float32Array;
        if (type == FloatType) {
            dataFloat = new Float32Array(size * size * size * 4);
        } else {
            dataFloat = new Float32Array(size * size * size * 4);
        }
        var maxValue:Float = 0.0;
        var index:Int = 0;

        while ((result = regExpDataPoints.exec(input)) != null) {
            var r:Float = Std.parseFloat(result[1]);
            var g:Float = Std.parseFloat(result[2]);
            var b:Float = Std.parseFloat(result[3]);

            maxValue = Math.max(maxValue, r, g, b);

            var bLayer:Int = index % size;
            var gLayer:Int = Math.floor(index / size) % size;
            var rLayer:Int = Math.floor(index / (size * size)) % size;

            // b grows first, then g, then r.
            var d4:Int = (bLayer * size * size + gLayer * size + rLayer) * 4;
            dataFloat[d4 + 0] = r;
            dataFloat[d4 + 1] = g;
            dataFloat[d4 + 2] = b;

            ++index;
        }

        // Determine the bit depth to scale the values to [0.0, 1.0].
        var bits:Int = Math.ceil(Math.log2(maxValue));
        var maxBitValue:Float = Math.pow(2, bits);

        var data:BytesBuffer;
        if (type == UnsignedByteType) {
            data = new BytesBuffer(size * size * size * 4);
        } else {
            data = dataFloat;
        }
        var scale:Float = type == UnsignedByteType ? 255 : 1;

        for (i in 0...data.length) {
            if (type == UnsignedByteType) {
                data.setUInt8(i, Std.int(dataFloat[i] / maxBitValue * scale));
            } else {
                data_FLOAT(i, dataFloat[i] / maxBitValue * scale);
            }
        }

        var texture3D:Data3DTexture = new Data3DTexture();
        texture3D.image.data = data;
        texture3D.image.width = size;
        texture3D.image.height = size;
        texture3D.image.depth = size;
        texture3D.format = RgbaFormat;
        texture3D.type = type;
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