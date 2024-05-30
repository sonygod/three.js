import haxe.io.Bytes;
import js.Browser;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Float64Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Int8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;

class LUT3dlLoader {
    public var type:Int;
    public var path:String;
    public var manager:Dynamic;

    public function new(manager:Dynamic) {
        this.type = js.html.Uint8Array;
        this.manager = manager;
    }

    public function setType(type:Int):LUT3dlLoader {
        if (type != js.html.Uint8Array && type != js.html.Float32Array) {
            throw js.Boot.typedError("Unsupported type", null);
        }
        this.type = type;
        return this;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var loader = js.Browser.createXMLHttpRequest();
        if (this.path != null) {
            loader.open("GET", this.path + url, true);
        } else {
            loader.open("GET", url, true);
        }
        loader.overrideMimeType("text/plain; charset=x-user-defined");
        loader.onreadystatechange = $bind(this, this._onLoad);
        loader.send(null);
    }

    public function parse(data:String):Dynamic {
        var regExpGridInfo = ~EReg("[\\d ]+$", "m");
        var regExpDataPoints = ~EReg("([\\d.e+-]+) +([\\d.e+-]+) +([\\d.e+-]+)", "gm");

        var result = regExpGridInfo.match(data);
        if (result == null) {
            throw js.Boot.typedError("Missing grid information", null);
        }

        var gridLines = result[0].split(" ");
        var gridStep = Std.parseFloat(gridLines[1]) - Std.parseFloat(gridLines[0]);
        var size = gridLines.length;
        var sizeSq = size * size;

        var dataFloat = new Float32Array(size * size * size * 4);
        var maxValue = 0.;
        var index = 0;

        while ((result = regExpDataPoints.match(data)) != null) {
            var r = Std.parseFloat(result[1]);
            var g = Std.parseFloat(result[2]);
            var b = Std.parseFloat(result[3]);

            maxValue = Math.max(maxValue, r, g, b);

            var bLayer = index % size;
            var gLayer = (index / size) % size;
            var rLayer = (index / sizeSq) % size;

            var d4 = (bLayer * sizeSq + gLayer * size + rLayer) * 4;
            dataFloat[d4] = r;
            dataFloat[d4 + 1] = g;
            dataFloat[d4 + 2] = b;

            index++;
        }

        var bits = Math.ceil(Math.log(maxValue) / Math.log(2));
        var maxBitValue = Math.pow(2, bits);

        var data:Dynamic;
        if (this.type == js.html.Uint8Array) {
            data = new Uint8Array(dataFloat.length);
        } else {
            data = dataFloat;
        }
        var scale = (this.type == js.html.Uint8Array) ? 255 : 1;

        var i = 0;
        while (i < data.length) {
            data[i] = dataFloat[i] / maxBitValue * scale;
            data[i + 1] = dataFloat[i + 1] / maxBitValue * scale;
            data[i + 2] = dataFloat[i + 2] / maxBitValue * scale;
            data[i + 3] = scale;
            i += 4;
        }

        var texture3D = new Data3DTexture();
        texture3D.image = new js.html.ImageData();
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

        return { size: size, texture3D: texture3D };
    }

    function _onLoad(event:Dynamic):Void {
        if (event.currentTarget.readyState == 4) {
            if (event.currentTarget.status == 200) {
                onLoad(this.parse(event.currentTarget.responseText));
            } else {
                var error = js.Boot.__instanceof(event.currentTarget.statusText, Error) ? event.currentTarget.statusText : new String(event.currentTarget.statusText);
                if (onError != null) {
                    onError(error);
                } else {
                    throw js.Boot.__instanceof(error, Error) ? error : new String(error);
                }
                this.manager.itemError(url);
            }
        }
    }
}

enum RGBAFormat {
}

enum ClampToEdgeWrapping {
}

enum LinearFilter {
}

class Data3DTexture {
}

class Loader {
}

enum UnsignedByteType {
}

enum FloatType {
}