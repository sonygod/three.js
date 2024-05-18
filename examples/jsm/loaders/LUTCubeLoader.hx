package three.js.examples.jsg.loaders;

import three.js.loaders.Loader;
import three.js.textures.Data3DTexture;
import three.js.textures.Texture;
import three.js.types.UnsignedByteType;
import three.js.types.FloatType;
import three.js.math.Vector3;
import three.js.loaders.FileLoader;
import three.js.constants.LinearFilter;
import three.js.constants.ClampToEdgeWrapping;

class LUTCubeLoader extends Loader {
    public var type:Dynamic;

    public function new(manager:Loader) {
        super(manager);
        this.type = UnsignedByteType;
    }

    public function setType(type:Dynamic):LUTCubeLoader {
        if (type != UnsignedByteType && type != FloatType) {
            throw new Error('LUTCubeLoader: Unsupported type');
        }
        this.type = type;
        return this;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
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

    private function parse(input:String):Dynamic {
        var regExpTitle = ~/TITLE +"([^"]*)"/;
        var regExpSize = ~/LUT_3D_SIZE +(\d+)/;
        var regExpDomainMin = ~/DOMAIN_MIN +([\d.]+) +([\d.]+) +([\d.]+)/;
        var regExpDomainMax = ~/DOMAIN_MAX +([\d.]+) +([\d.]+) +([\d.]+)/;
        var regExpDataPoints = ~/^([\d.e+-]+) +([\d.e+-]+) +([\d.e+-]+) *$/gm;

        var result = regExpTitle.exec(input);
        var title:String = (result != null) ? result[1] : null;

        result = regExpSize.exec(input);

        if (result == null) {
            throw new Error('LUTCubeLoader: Missing LUT_3D_SIZE information');
        }

        var size:Int = Std.parseInt(result[1]);
        var length:Int = size * size * size * 4;
        var data:Dynamic = (this.type == UnsignedByteType) ? new Uint8Array(length) : new Float32Array(length);

        var domainMin:Vector3 = new Vector3(0, 0, 0);
        var domainMax:Vector3 = new Vector3(1, 1, 1);

        result = regExpDomainMin.exec(input);

        if (result != null) {
            domainMin.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
        }

        result = regExpDomainMax.exec(input);

        if (result != null) {
            domainMax.set(Std.parseFloat(result[1]), Std.parseFloat(result[2]), Std.parseFloat(result[3]));
        }

        if (domainMin.x > domainMax.x || domainMin.y > domainMax.y || domainMin.z > domainMax.z) {
            throw new Error('LUTCubeLoader: Invalid input domain');
        }

        var scale:Float = (this.type == UnsignedByteType) ? 255 : 1;
        var i:Int = 0;

        while ((result = regExpDataPoints.exec(input)) != null) {
            data[i++] = Std.parseFloat(result[1]) * scale;
            data[i++] = Std.parseFloat(result[2]) * scale;
            data[i++] = Std.parseFloat(result[3]) * scale;
            data[i++] = scale;
        }

        var texture3D:Data3DTexture = new Data3DTexture();
        texture3D.image.data = data;
        texture3D.image.width = size;
        texture3D.image.height = size;
        texture3D.image.depth = size;
        texture3D.type = this.type;
        texture3D.magFilter = LinearFilter;
        texture3D.minFilter = LinearFilter;
        texture3D.wrapS = ClampToEdgeWrapping;
        texture3D.wrapT = ClampToEdgeWrapping;
        texture3D.wrapR = ClampToEdgeWrapping;
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