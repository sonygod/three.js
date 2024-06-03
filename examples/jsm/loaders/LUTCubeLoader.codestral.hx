import three.data.Data3DTexture;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.math.Vector3;
import three.textures.Texture;
import haxe.io.Bytes;

class LUTCubeLoader extends Loader {
    public var type: Int = Texture.UNSIGNED_BYTE;

    public function new(manager: LoadingManager) {
        super(manager);
    }

    public function setType(type: Int): LUTCubeLoader {
        if (type != Texture.UNSIGNED_BYTE && type != Texture.FLOAT) {
            throw 'LUTCubeLoader: Unsupported type';
        }

        this.type = type;
        return this;
    }

    public function load(url: String, onLoad: (LUTCube) -> Void, onProgress: (ProgressEvent) -> Void, onError: (ErrorEvent) -> Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('text');
        loader.load(url, function(text: String) {
            try {
                onLoad(this.parse(text));
            } catch (e: Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(input: String): LUTCube {
        var regExpTitle = new EReg("TITLE +\"([^\"]*)\"", "g");
        var regExpSize = new EReg("LUT_3D_SIZE +(\\d+)", "g");
        var regExpDomainMin = new EReg("DOMAIN_MIN +([\\d.]+) +([\\d.]+) +([\\d.]+)", "g");
        var regExpDomainMax = new EReg("DOMAIN_MAX +([\\d.]+) +([\\d.]+) +([\\d.]+)", "g");
        var regExpDataPoints = new EReg("^([\\d.e+-]+) +([\\d.e+-]+) +([\\d.e+-]+) *$", "gm");

        var result = regExpTitle.match(input);
        var title = (result != null) ? result[1] : null;

        result = regExpSize.match(input);

        if (result == null) {
            throw 'LUTCubeLoader: Missing LUT_3D_SIZE information';
        }

        var size = Std.parseInt(result[1]);
        var length = size * size * size * 4;
        var data = new Bytes(length);

        var domainMin = new Vector3(0, 0, 0);
        var domainMax = new Vector3(1, 1, 1);

        result = regExpDomainMin.match(input);

        if (result != null) {
            domainMin.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
        }

        result = regExpDomainMax.match(input);

        if (result != null) {
            domainMax.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
        }

        if (domainMin.x > domainMax.x || domainMin.y > domainMax.y || domainMin.z > domainMax.z) {
            throw 'LUTCubeLoader: Invalid input domain';
        }

        var scale = this.type == Texture.UNSIGNED_BYTE ? 255 : 1;
        var i = 0;

        while ((result = regExpDataPoints.match(input)) != null) {
            data.setFloat(i, Std.parseFloat(result[1]) * scale);
            i += 4;
            data.setFloat(i, Std.parseFloat(result[2]) * scale);
            i += 4;
            data.setFloat(i, Std.parseFloat(result[3]) * scale);
            i += 4;
            data.setFloat(i, scale);
            i += 4;
        }

        var texture3D = new Data3DTexture(data, size, size, size);
        texture3D.type = this.type;
        texture3D.magFilter = Texture.LINEAR;
        texture3D.minFilter = Texture.LINEAR;
        texture3D.wrapS = Texture.CLAMP_TO_EDGE;
        texture3D.wrapT = Texture.CLAMP_TO_EDGE;
        texture3D.wrapR = Texture.CLAMP_TO_EDGE;
        texture3D.generateMipmaps = false;
        texture3D.needsUpdate = true;

        return {
            title : title,
            size : size,
            domainMin : domainMin,
            domainMax : domainMax,
            texture3D : texture3D,
        };
    }
}