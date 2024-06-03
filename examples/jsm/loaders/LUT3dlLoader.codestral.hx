import js.html.File;
import js.html.FileReader;
import js.html.Blob;
import js.html.RegExp;
import js.html.RegExpMatch;
import js.ArrayBuffer;
import js.Float32Array;
import js.Uint8Array;

import three.loaders.Loader;
import three.constants.TextureConstants;
import three.constants.Wrapping;
import three.constants.TextureFilter;
import three.constants.PixelFormat;
import three.constants.PixelType;
import three.textures.Data3DTexture;
import three.textures.DataTexture;
import three.textures.Texture;

class LUT3dlLoader extends Loader {

    private var _type:Int = PixelType.UNSIGNED_BYTE;

    public function new(manager:Loader.LoadingManager) {
        super(manager);
    }

    public function setType(type:Int):LUT3dlLoader {
        if (type !== PixelType.UNSIGNED_BYTE && type !== PixelType.FLOAT) {
            throw "LUT3dlLoader: Unsupported type";
        }
        this._type = type;
        return this;
    }

    public function load(url:String, onLoad:(texture:Data3DTexture) -> Void, onProgress:(event:ProgressEvent) -> Void, onError:(event:Error) -> Void) {
        var request = new js.html.XMLHttpRequest();
        request.onreadystatechange = (_) => {
            if (request.readyState === js.html.XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    var reader = new FileReader();
                    reader.onload = (_) => {
                        var text = reader.result;
                        try {
                            onLoad(this.parse(text));
                        } catch (e) {
                            if (onError != null) {
                                onError(e);
                            } else {
                                trace(e);
                            }
                            this.manager.itemError(url);
                        }
                    };
                    reader.readAsText(request.response);
                } else if (request.status > 0) {
                    if (onError != null) {
                        onError(new Error("Couldn't load [" + url + "] [" + request.status + "]"));
                    }
                    this.manager.itemError(url);
                }
            } else if (request.readyState === js.html.XMLHttpRequest.HEADERS_RECEIVED) {
                if (onProgress != null) {
                    onProgress(new ProgressEvent("progress"));
                }
            }
        };
        request.open("GET", url, true);
        request.responseType = "blob";
        request.send(null);
    }

    public function parse(input:String):Data3DTexture {
        var regExpGridInfo = new RegExp("^[\\d ]+\$", "m");
        var regExpDataPoints = new RegExp("^([\\d.e+-]+) +([\\d.e+-]+) +([\\d.e+-]+) *\$", "gm");

        var result = regExpGridInfo.exec(input);
        if (result == null) {
            throw "LUT3dlLoader: Missing grid information";
        }

        var gridLines = result[0].trim().split(new RegExp("\\s+", "g")).map(Std.parseFloat);
        var gridStep = gridLines[1] - gridLines[0];
        var size = gridLines.length;
        var sizeSq = size * size;

        for (i in 1...gridLines.length) {
            if (gridStep !== (gridLines[i] - gridLines[i - 1])) {
                throw "LUT3dlLoader: Inconsistent grid size";
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
            var rLayer = Math.floor(index / sizeSq) % size;

            var d4 = (bLayer * sizeSq + gLayer * size + rLayer) * 4;
            dataFloat[d4 + 0] = r;
            dataFloat[d4 + 1] = g;
            dataFloat[d4 + 2] = b;

            ++index;
        }

        var bits = Math.ceil(Math.log2(maxValue));
        var maxBitValue = Math.pow(2, bits);

        var data:Array<haxe.lang.Dynamic>;
        var scale = this._type === PixelType.UNSIGNED_BYTE ? 255 : 1;

        if (this._type === PixelType.UNSIGNED_BYTE) {
            data = new Uint8Array(dataFloat.length);
        } else {
            data = dataFloat;
        }

        for (i in 0...data.length) {
            if (i % 4 !== 3) {
                data[i] = dataFloat[i] / maxBitValue * scale;
            } else {
                data[i] = scale;
            }
        }

        var texture3D = new Data3DTexture(data, size, size, size);
        texture3D.format = PixelFormat.RGBA;
        texture3D.type = this._type;
        texture3D.magFilter = TextureFilter.LINEAR;
        texture3D.minFilter = TextureFilter.LINEAR;
        texture3D.wrapS = Wrapping.CLAMP_TO_EDGE;
        texture3D.wrapT = Wrapping.CLAMP_TO_EDGE;
        texture3D.wrapR = Wrapping.CLAMP_TO_EDGE;
        texture3D.generateMipmaps = false;
        texture3D.needsUpdate = true;

        return texture3D;
    }
}