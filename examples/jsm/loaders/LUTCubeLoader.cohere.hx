import haxe.io.Bytes;
import js.Browser;
import js.html.HttpRequest;
import js.html.HttpRequestResponseType;
import js.html.HttpRequestType;
import js.RegExp;

class LUTCubeLoader {
    private manager: Dynamic;
    private type: Dynamic;

    public function new(manager: Dynamic) {
        this.manager = manager;
        this.type = js.Browser.window.UnsignedByteType;
    }

    public function setType(type: Dynamic): LUTCubeLoader {
        if (type != js.Browser.window.UnsignedByteType && type != js.Browser.window.FloatType) {
            throw "LUTCubeLoader: Unsupported type";
        }

        this.type = type;
        return this;
    }

    public function load(url: String, onLoad: Dynamic -> Void, onProgress: Dynamic -> Void, onError: Dynamic -> Void): Void {
        var loader = js.Browser.window.FileLoader.create(this.manager);
        loader.setPath(this.manager.get_path());
        loader.setResponseType(HttpRequestResponseType.Text);
        loader.load(url, (text) -> {
            try {
                onLoad(this.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    js.Browser.console.error(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(input: String): Dynamic {
        var regExpTitle = EReg("#TITLE +\"([^\"]*)\"#", "g");
        var regExpSize = EReg("LUT_3D_SIZE +(\\d+)", "g");
        var regExpDomainMin = EReg("DOMAIN_MIN +(\\d+\\.\\d+) +(\\d+\\.\\d+) +(\\d+\\.\\d+)", "g");
        var regExpDomainMax = EReg("DOMAIN_MAX +(\\d+\\.\\d+) +(\\d+\\.\\d+) +(\\d+\\.\\d+)", "g");
        var regExpDataPoints = EReg("^([\\d.e+-]+) +([\\d.e+-]+) +([\\d.e+-]+) *$", "g");

        var result = regExpTitle.match(input);
        var title = result != null ? result[1] : null;

        result = regExpSize.match(input);
        if (result == null) {
            throw "LUTCubeLoader: Missing LUT_3D_SIZE information";
        }

        var size = Std.parseInt(result[1]);
        var length = size * size * size * 4;
        var data: Bytes;
        if (this.type == js.Browser.window.UnsignedByteType) {
            data = Bytes.alloc(length);
        } else {
            data = Bytes.allocFloat(length);
        }

        var domainMin = js.Browser.window.Vector3.create(0, 0, 0);
        var domainMax = js.Browser.window.Vector3.create(1, 1, 1);

        result = regExpDomainMin.match(input);
        if (result != null) {
            domainMin.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
        }

        result = regExpDomainMax.match(input);
        if (result != null) {
            domainMax.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
        }

        if (domainMin.x > domainMax.x || domainMin.y > domainMax.y || domainMin.z > domainMax.z) {
            throw "LUTCubeLoader: Invalid input domain";
        }

        var scale = if (this.type == js.Browser.window.UnsignedByteType) 255 else 1;
        var i = 0;
        while (true) {
            result = regExpDataPoints.match(input);
            if (result == null) {
                break;
            }
            data.setFloat(i, Std.parseFloat(result[1]) * scale);
            data.setFloat(i + 1, Std.parseFloat(result[2]) * scale);
            data.setFloat(i + 2, Std.parseFloat(result[3]) * scale);
            data.setFloat(i + 3, scale);
            i += 4;
        }

        var texture3D = js.Browser.window.Data3DTexture.create();
        texture3D.image.data = data;
        texture3D.image.width = size;
        texture3D.image.height = size;
        texture3D.image.depth = size;
        texture3D.type = this.type;
        texture3D.magFilter = js.Browser.window.LinearFilter;
        texture3D.minFilter = js.Browser.window.LinearFilter;
        texture3D.wrapS = js.Browser.window.ClampToEdgeWrapping;
        texture3D.wrapT = js.Browser.window.ClampToEdgeWrapping;
        texture3D.wrapR = js.Browser.window.ClampToEdgeWrapping;
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