import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Loader;
import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;

class DRACOLoader extends Loader {

    public var decoderPath:String;
    public var decoderConfig:Dynamic;
    public var decoderBinary:Dynamic;
    public var decoderPending:Dynamic;

    public var workerLimit:Int;
    public var workerPool:Array<Dynamic>;
    public var workerNextTaskID:Int;
    public var workerSourceURL:String;

    public var defaultAttributeIDs:Dynamic;
    public var defaultAttributeTypes:Dynamic;

    public function new(manager:Dynamic) {
        super(manager);

        this.decoderPath = '';
        this.decoderConfig = {};
        this.decoderBinary = null;
        this.decoderPending = null;

        this.workerLimit = 4;
        this.workerPool = [];
        this.workerNextTaskID = 1;
        this.workerSourceURL = '';

        this.defaultAttributeIDs = {
            'position': 'POSITION',
            'normal': 'NORMAL',
            'color': 'COLOR',
            'uv': 'TEX_COORD'
        };
        this.defaultAttributeTypes = {
            'position': 'Float32Array',
            'normal': 'Float32Array',
            'color': 'Float32Array',
            'uv': 'Float32Array'
        };
    }

    public function setDecoderPath(path:String):DRACOLoader {
        this.decoderPath = path;
        return this;
    }

    public function setDecoderConfig(config:Dynamic):DRACOLoader {
        this.decoderConfig = config;
        return this;
    }

    public function setWorkerLimit(workerLimit:Int):DRACOLoader {
        this.workerLimit = workerLimit;
        return this;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, (buffer:Dynamic) => {
            this.parse(buffer, onLoad, onError);
        }, onProgress, onError);
    }

    public function parse(buffer:Dynamic, onLoad:Dynamic, onError:Dynamic = ()=>{}):Void {
        this.decodeDracoFile(buffer, onLoad, null, null, SRGBColorSpace, onError).catch(onError);
    }

    public function decodeDracoFile(buffer:Dynamic, callback:Dynamic, attributeIDs:Dynamic, attributeTypes:Dynamic, vertexColorSpace:Int = LinearSRGBColorSpace, onError:Dynamic = () => {}):Promise<Dynamic> {
        var taskConfig = {
            'attributeIDs': attributeIDs || this.defaultAttributeIDs,
            'attributeTypes': attributeTypes || this.defaultAttributeTypes,
            'useUniqueIDs': !!attributeIDs,
            'vertexColorSpace': vertexColorSpace,
        };

        return this.decodeGeometry(buffer, taskConfig).then(callback).catch(onError);
    }

    // ... other methods ...
}