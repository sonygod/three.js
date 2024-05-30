import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Loader;
import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;

class DRACOLoader extends Loader {

    var decoderPath:String;
    var decoderConfig:Dynamic;
    var decoderBinary:Dynamic;
    var decoderPending:Promise<Dynamic>;

    var workerLimit:Int;
    var workerPool:Array<Worker>;
    var workerNextTaskID:Int;
    var workerSourceURL:String;

    var defaultAttributeIDs:Dynamic;
    var defaultAttributeTypes:Dynamic;

    var _taskCache:WeakMap<ArrayBuffer, Dynamic>;

    public function new(manager:Loader) {
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
            position: 'POSITION',
            normal: 'NORMAL',
            color: 'COLOR',
            uv: 'TEX_COORD'
        };
        this.defaultAttributeTypes = {
            position: 'Float32Array',
            normal: 'Float32Array',
            color: 'Float32Array',
            uv: 'Float32Array'
        };

        this._taskCache = new WeakMap();
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

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var loader = new FileLoader(this.manager);

        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, (buffer:ArrayBuffer) -> {
            this.parse(buffer, onLoad, onError);
        }, onProgress, onError);
    }

    public function parse(buffer:ArrayBuffer, onLoad:Dynamic->Void, onError:Dynamic->Void = () -> {}):Void {
        this.decodeDracoFile(buffer, onLoad, null, null, SRGBColorSpace, onError).catch(onError);
    }

    public function decodeDracoFile(buffer:ArrayBuffer, callback:Dynamic->Void, attributeIDs:Dynamic, attributeTypes:Dynamic, vertexColorSpace:Dynamic = LinearSRGBColorSpace, onError:Dynamic->Void = () -> {}):Promise<Dynamic> {
        var taskConfig = {
            attributeIDs: attributeIDs || this.defaultAttributeIDs,
            attributeTypes: attributeTypes || this.defaultAttributeTypes,
            useUniqueIDs: !! attributeIDs,
            vertexColorSpace: vertexColorSpace,
        };

        return this.decodeGeometry(buffer, taskConfig).then(callback).catch(onError);
    }

    public function decodeGeometry(buffer:ArrayBuffer, taskConfig:Dynamic):Promise<Dynamic> {
        var taskKey = haxe.Json.stringify(taskConfig);

        if (_taskCache.has(buffer)) {
            var cachedTask = _taskCache.get(buffer);

            if (cachedTask.key === taskKey) {
                return cachedTask.promise;
            } else if (buffer.byteLength == 0) {
                throw 'THREE.DRACOLoader: Unable to re-decode a buffer with different settings. Buffer has already been transferred.';
            }
        }

        var worker:Worker;
        var taskID = this.workerNextTaskID++;
        var taskCost = buffer.byteLength;

        var geometryPending = this._getWorker(taskID, taskCost)
            .then((_worker:Worker) -> {
                worker = _worker;

                return new Promise((resolve, reject) -> {
                    worker._callbacks[taskID] = {resolve: resolve, reject: reject};
                    worker.postMessage({type: 'decode', id: taskID, taskConfig: taskConfig, buffer: buffer}, [buffer]);
                });
            })
            .then((message:Dynamic) -> this._createGeometry(message.geometry));

        geometryPending
            .catch(() -> {})
            .then(() -> {
                if (worker && taskID) {
                    this._releaseTask(worker, taskID);
                }
            });

        _taskCache.set(buffer, {
            key: taskKey,
            promise: geometryPending
        });

        return geometryPending;
    }

    private function _createGeometry(geometryData:Dynamic):BufferGeometry {
        var geometry = new BufferGeometry();

        if (geometryData.index) {
            geometry.setIndex(new BufferAttribute(geometryData.index.array, 1));
        }

        for (i in 0...geometryData.attributes.length) {
            var result = geometryData.attributes[i];
            var name = result.name;
            var array = result.array;
            var itemSize = result.itemSize;

            var attribute = new BufferAttribute(array, itemSize);

            if (name == 'color') {
                this._assignVertexColorSpace(attribute, result.vertexColorSpace);
                attribute.normalized = (array instanceof Float32Array) == false;
            }

            geometry.setAttribute(name, attribute);
        }

        return geometry;
    }

    private function _assignVertexColorSpace(attribute:BufferAttribute, inputColorSpace:Dynamic):Void {
        if (inputColorSpace != SRGBColorSpace) return;

        var _color = new Color();

        for (i in 0...attribute.count) {
            _color.fromBufferAttribute(attribute, i).convertSRGBToLinear();
            attribute.setXYZ(i, _color.r, _color.g, _color.b);
        }
    }

    private function _loadLibrary(url:String, responseType:String):Promise<Dynamic> {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.decoderPath);
        loader.setResponseType(responseType);
        loader.setWithCredentials(this.withCredentials);

        return new Promise((resolve, reject) -> {
            loader.load(url, resolve, null, reject);
        });
    }

    public function preload():DRACOLoader {
        this._initDecoder();
        return this;
    }

    private function _initDecoder():Promise<Void> {
        if (this.decoderPending) return this.decoderPending;

        var useJS = (typeof WebAssembly != 'object') || (this.decoderConfig.type == 'js');
        var librariesPending = [];

        if (useJS) {
            librariesPending.push(this._loadLibrary('draco_decoder.js', 'text'));
        } else {
            librariesPending.push(this._loadLibrary('draco_wasm_wrapper.js', 'text'));
            librariesPending.push(this._loadLibrary('draco_decoder.wasm', 'arraybuffer'));
        }

        this.decoderPending = Promise.all(librariesPending)
            .then((libraries:Array<Dynamic>) -> {
                var jsContent = libraries[0];

                if (!useJS) {
                    this.decoderConfig.wasmBinary = libraries[1];
                }

                var fn = DRACOWorker.toString();

                var body = [
                    '/* draco decoder */',
                    jsContent,
                    '',
                    '/* worker */',
                    fn.substring(fn.indexOf('{') + 1, fn.lastIndexOf('}'))
                ].join('\n');

                this.workerSourceURL = haxe.Resource.fromString(body).url;
            });

        return this.decoderPending;
    }

    private function _getWorker(taskID:Int, taskCost:Int):Promise<Worker> {
        return this._initDecoder().then(() -> {
            if (this.workerPool.length < this.workerLimit) {
                var worker = new Worker(this.workerSourceURL);

                worker._callbacks = {};
                worker._taskCosts = {};
                worker._taskLoad = 0;

                worker.postMessage({type: 'init', decoderConfig: this.decoderConfig});

                worker.onmessage = (e:MessageEvent) -> {
                    var message = e.data;

                    switch (message.type) {
                        case 'decode':
                            worker._callbacks[message.id].resolve(message);
                            break;

                        case 'error':
                            worker._callbacks[message.id].reject(message);
                            break;

                        default:
                            trace('THREE.DRACOLoader: Unexpected message, "' + message.type + '"');
                    }
                };

                this.workerPool.push(worker);
            } else {
                this.workerPool.sort((a, b) -> a._taskLoad > b._taskLoad ? -1 : 1);
            }

            var worker = this.workerPool[this.workerPool.length - 1];
            worker._taskCosts[taskID] = taskCost;
            worker._taskLoad += taskCost;
            return worker;
        });
    }

    private function _releaseTask(worker:Worker, taskID:Int):Void {
        worker._taskLoad -= worker._taskCosts[taskID];
        delete worker._callbacks[taskID];
        delete worker._taskCosts[taskID];
    }

    public function debug():Void {
        trace('Task load: ', this.workerPool.map((worker) -> worker._taskLoad));
    }

    public function dispose():DRACOLoader {
        for (i in 0...this.workerPool.length) {
            this.workerPool[i].terminate();
        }

        this.workerPool.length = 0;

        if (this.workerSourceURL != '') {
            haxe.Resource.fromUrl(this.workerSourceURL).release();
        }

        return this;
    }
}

/* WEB WORKER */

class DRACOWorker {
    static function new() {
        // Web Worker code here
    }
}