package three.js.examples.jm.loaders;

import three.js.Data3DTexture;
import three.js.FileLoader;
import three.js.Loader;
import three.js.LinearFilter;
import three.js.RgbaFormat;
import three.js.TextureWrapping;
import three.js.UnsignedByteType;
import three.js.type.FloatType;

class LUT3dlLoader extends Loader {
    public var type:three.js.type.UnsignedByteType;

    public function new(manager:Loader) {
        super(manager);
        this.type = UnsignedByteType;
    }

    public function setType(type:three.js.type.UnsignedByteType | three.js.type.FloatType):LUT3dlLoader {
        if (type != UnsignedByteType && type != FloatType) {
            throw new Error('LUT3dlLoader: Unsupported type');
        }
        this.type = type;
        return this;
    }

    public function load(url:String, onLoad:(result:Any) -> Void, onProgress:(progress:Float) -> Void, onError:(error:String) -> Void):Void {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('text');
        loader.load(url, function(text:String) {
            try {
                onLoad(parse(text));
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

    private function parse(input:String):{size:Int, texture3D:Data3DTexture} {
        var regExpGridInfo = ~/^[\d ]+$/m;
        var regExpDataPoints = ~/^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

        var result:Array<String> = regExpGridInfo.exec(input);
        if (result == null) {
            throw new Error('LUT3dlLoader: Missing grid information');
        }

        var gridLines:Array<String> = result[0].trim().split ~/ +/g;
        gridLines = gridLines.map(function(s:String):Int { return Std.parseInt(s); });
        var gridStep:Int = gridLines[1] - gridLines[0];
        var size:Int = gridLines.length;
        var sizeSq:Int = size * size;

        for (i in 1...gridLines.length) {
            if (gridStep != gridLines[i] - gridLines[i - 1]) {
                throw new Error('LUT3dlLoader: Inconsistent grid size');
            }
        }

        var dataFloat:Array<Float> = new Array<Float>(size * size * size * 4);
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

            var d4:Int = (bLayer * size * size + gLayer * size + rLayer) * 4;
            dataFloat[d4 + 0] = r;
            dataFloat[d4 + 1] = g;
            dataFloat[d4 + 2] = b;

            index++;
        }

        var bits:Int = Math.ceil(Math.log(maxValue) / Math.log(2));
        var maxBitValue:Float = Math.pow(2, bits);

        var data:Array<Float>;
        if (type == UnsignedByteType) {
            data = new Array<Float>(dataFloat.length);
        } else {
            data = dataFloat;
        }

        var scale:Float = type == UnsignedByteType ? 255 : 1;

        for (i in 0...data.length) {
            data[i] = dataFloat[i] / maxBitValue * scale;
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
        texture3D.wrapS = TextureWrapping.ClampToEdgeWrapping;
        texture3D.wrapT = TextureWrapping.ClampToEdgeWrapping;
        texture3D.wrapR = TextureWrapping.ClampToEdgeWrapping;
        texture3D.generateMipmaps = false;
        texture3D.needsUpdate = true;

        return { size: size, texture3D: texture3D };
    }
}