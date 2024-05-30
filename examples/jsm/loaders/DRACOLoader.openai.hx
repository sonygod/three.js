package three.js.loaders;

import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Loader;
import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;

class DRACOLoader extends Loader {
    private var _taskCache:WeakMap<ByteBuffer, { key:String, promise:Promise<BufferGeometry> }>;

    public function new(manager:Loader) {
        super(manager);
        _taskCache = new WeakMap();
        decoderPath = '';
        decoderConfig = {};
        decoderBinary = null;
        decoderPending = null;
        workerLimit = 4;
        workerPool = [];
        workerNextTaskID = 1;
        workerSourceURL = '';
        defaultAttributeIDs = {
            position: 'POSITION',
            normal: 'NORMAL',
            color: 'COLOR',
            uv: 'TEX_COORD'
        };
        defaultAttributeTypes = {
            position: Float32Array,
            normal: Float32Array,
            color: Float32Array,
            uv: Float32Array
        };
    }

    public function setDecoderPath(path:String):DRACOLoader {
        decoderPath = path;
        return this;
    }

    public function setDecoderConfig(config:{}):DRACOLoader {
        decoderConfig = config;
        return this;
    }

    public function setWorkerLimit(limit:Int):DRACOLoader {
        workerLimit = limit;
        return this;
    }

    public function load(url:String, onLoad:BufferGeometry->Void, onProgress:ProgressEvent->Void, onError:String->Void):Void {
        var loader:FileLoader = new FileLoader(manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);
        loader.load(url, (buffer:ByteBuffer) -> {
            parse(buffer, onLoad, onError);
        }, onProgress, onError);
    }

    private function parse(buffer:ByteBuffer, onLoad:BufferGeometry->Void, onError:String->Void):Void {
        decodeDracoFile(buffer, onLoad, null, null, SRGBColorSpace, onError).catchError(onError);
    }

    private function decodeDracoFile(buffer:ByteBuffer, callback:BufferGeometry->Void, attributeIDs:{}, attributeTypes:{}, vertexColorSpace:ColorSpace = SRGBColorSpace, onError:String->Void):Promise<BufferGeometry> {
        var taskConfig = {
            attributeIDs: attributeIDs || defaultAttributeIDs,
            attributeTypes: attributeTypes || defaultAttributeTypes,
            useUniqueIDs: attributeIDs != null,
            vertexColorSpace: vertexColorSpace
        };
        return decodeGeometry(buffer, taskConfig).then(callback).catchError(onError);
    }

    private function decodeGeometry(buffer:ByteBuffer, taskConfig:{}):Promise<BufferGeometry> {
        var taskKey = Json.stringify(taskConfig);
        if (_taskCache.has(buffer)) {
            var cachedTask = _taskCache.get(buffer);
            if (cachedTask.key == taskKey) {
                return cachedTask.promise;
            } else if (buffer.byteLength == 0) {
                throw new Error('THREE.DRACOLoader: Unable to re-decode a buffer with different settings. Buffer has already been transferred.');
            }
        }
        var worker = _getWorker().then((worker) -> {
            var taskID = workerNextTaskID++;
            var taskCost = buffer.byteLength;
            return worker.postMessage({ type: 'decode', id: taskID, taskConfig: taskConfig, buffer: buffer }, [buffer]).then((message) -> {
                return _createGeometry(message.geometry);
            });
        });
        _taskCache.set(buffer, { key: taskKey, promise: worker });
        return worker;
    }

    private function _createGeometry(geometryData:{}):BufferGeometry {
        var geometry = new BufferGeometry();
        if (geometryData.index != null) {
            geometry.setIndex(new BufferAttribute(geometryData.index.array, 1));
        }
        for (attribute in geometryData.attributes) {
            var name = attribute.name;
            var array = attribute.array;
            var itemSize = attribute.itemSize;
            var attribute = new BufferAttribute(array, itemSize);
            if (name == 'color') {
                _assignVertexColorSpace(attribute, attribute.vertexColorSpace);
                attribute.normalized = (array instanceof Float32Array) == false;
            }
            geometry.setAttribute(name, attribute);
        }
        return geometry;
    }

    private function _assignVertexColorSpace(attribute:BufferAttribute, inputColorSpace:ColorSpace):Void {
        if (inputColorSpace != SRGBColorSpace) return;
        var color = new Color();
        for (i in 0...attribute.count) {
            color.fromBufferAttribute(attribute, i).convertSRGBToLinear();
            attribute.setXYZ(i, color.r, color.g, color.b);
        }
    }

    // ...
}