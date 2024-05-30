import haxe.io.Bytes;

class DRACOLoader {
    var decoderPath: String;
    var decoderConfig: { };
    var decoderBinary: Bytes;
    var decoderPending: Promise<Void>;
    var workerLimit: Int;
    var workerPool: Array<Worker>;
    var workerNextTaskID: Int;
    var workerSourceURL: String;
    var defaultAttributeIDs: { };
    var defaultAttributeTypes: { };

    public function new(manager: { }) {
        this.decoderPath = "";
        this.decoderConfig = { };
        this.decoderBinary = null;
        this.decoderPending = null;
        this.workerLimit = 4;
        this.workerPool = [];
        this.workerNextTaskID = 1;
        this.workerSourceURL = "";
        this.defaultAttributeIDs = {
            "position": "POSITION",
            "normal": "NORMAL",
            "color": "COLOR",
            "uv": "TEX_COORD"
        };
        this.defaultAttributeTypes = {
            "position": Float32Array,
            "normal": Float32Array,
            "color": Float32Array,
            "uv": Float32Array
        };
    }

    public function setDecoderPath(path: String): DRACOLoader {
        this.decoderPath = path;
        return this;
    }

    public function setDecoderConfig(config: { }): DRACOLoader {
        this.decoderConfig = config;
        return this;
    }

    public function setWorkerLimit(workerLimit: Int): DRACOLoader {
        this.workerLimit = workerLimit;
        return this;
    }

    public function load(url: String, onLoad: { -> Void }, onProgress: { -> Void }, onError: { -> Void }): Void {
        var loader = new FileLoader(this.manager);
        loader.path = this.path;
        loader.responseType = "arraybuffer";
        loader.requestHeader = this.requestHeader;
        loader.withCredentials = this.withCredentials;
        loader.load(url, $bind(this, function(buffer) {
            this.parse(buffer, onLoad, onError);
        }), onProgress, onError);
    }

    public function parse(buffer: Bytes, onLoad: { -> Void }, onError: { -> Void } = null): Void {
        this.decodeDracoFile(buffer, onLoad, null, null, SRGBColorSpace, onError).catch($bind(onError, onError));
    }

    public function decodeDracoFile(buffer: Bytes, callback: { -> Void }, attributeIDs: { }, attributeTypes: { }, vertexColorSpace: ColorSpace = LinearSRGBColorSpace, onError: { -> Void } = null): Promise<Void> {
        var taskConfig = {
            "attributeIDs": attributeIDs ?? this.defaultAttributeIDs,
            "attributeTypes": attributeTypes ?? this.defaultAttributeTypes,
            "useUniqueIDs": Std.is(attributeIDs),
            "vertexColorSpace": vertexColorSpace
        };
        return this.decodeGeometry(buffer, taskConfig).then(callback).catch(onError);
    }

    public function decodeGeometry(buffer: Bytes, taskConfig: { }): Promise<Void> {
        var taskKey = Json.stringify(taskConfig);
        if (_taskCache.exists(buffer)) {
            var cachedTask = _taskCache.get(buffer);
            if (cachedTask.key == taskKey) {
                return cachedTask.promise;
            } else if (buffer.length == 0) {
                throw new Error("THREE.DRACOLoader: Unable to re-decode a buffer with different settings. Buffer has already been transferred.");
            }
        }
        var worker: Worker;
        var taskID = this.workerNextTaskID++;
        var taskCost = buffer.length;
        var geometryPending = this._getWorker(taskID, taskCost).then(function(_worker) {
            worker = _worker;
            return new Promise(function(resolve, reject) {
                worker._callbacks[taskID] = {
                    "resolve": resolve,
                    "reject": reject
                };
                worker.postMessage({
                    "type": "decode",
                    "id": taskID,
                    "taskConfig": taskConfig,
                    "buffer": buffer
                }, [buffer]);
            });
        }).then(function(message) {
            return this._createGeometry(message.geometry);
        }).catch(function() {
            return true;
        }).then(function() {
            if (worker != null && taskID != null) {
                this._releaseTask(worker, taskID);
            }
        }).then(function() {
            _taskCache.set(buffer, {
                "key": taskKey,
                "promise": geometryPending
            });
        });
        return geometryPending;
    }

    public function _createGeometry(geometryData: { }): BufferGeometry {
        var geometry = new BufferGeometry();
        if (geometryData.index != null) {
            geometry.setIndex(new BufferAttribute(geometryData.index.array, 1));
        }
        var _g = 0;
        while (_g < geometryData.attributes.length) {
            var result = geometryData.attributes[_g];
            ++_g;
            var name = result.name;
            var array = result.array;
            var itemSize = result.itemSize;
            var attribute = new BufferAttribute(array, itemSize);
            if (name == "color") {
                this._assignVertexColorSpace(attribute, result.vertexColorSpace);
                attribute.normalized = !(array instanceof Float32Array);
            }
            geometry.setAttribute(name, attribute);
        }
        return geometry;
    }

    public function _assignVertexColorSpace(attribute: BufferAttribute, inputColorSpace: ColorSpace) {
        if (inputColorSpace != SRGBColorSpace) {
            return;
        }
        var _color = new Color();
        var _g = 0;
        while (_g < attribute.count) {
            var i = _g++;
            _color.fromBufferAttribute(attribute, i).convertSRGBToLinear();
            attribute.setXYZ(i, _color.r, _color.g, _color.b);
        }
    }

    public function _loadLibrary(url: String, responseType: String): Promise<Void> {
        var loader = new FileLoader(this.manager);
        loader.path = this.decoderPath;
        loader.responseType = responseType;
        loader.withCredentials = this.withCredentials;
        return new Promise(function(resolve, reject) {
            loader.load(url, resolve, undefined, reject);
        });
    }

    public function preload(): DRACOLoader {
        this._initDecoder();
        return this;
    }

    public function _initDecoder(): Promise<Void> {
        if (this.decoderPending != null) {
            return this.decoderPending;
        }
        var useJS = typeof WebAssembly != "object" || this.decoderConfig.type == "js";
        var librariesPending = [];
        if (useJS) {
            librariesPending.push(this._loadLibrary("draco_decoder.js", "text"));
        } else {
            librariesPending.push(this._loadLibrary("draco_wasm_wrapper.js", "text"));
            librariesPending.push(this._loadLibrary("draco_decoder.wasm", "arraybuffer"));
        }
        this.decoderPending = Promise.all(librariesPending).then(function(libraries) {
            var jsContent = libraries[0];
            if (!useJS) {
                this.decoderConfig.wasmBinary = libraries[1];
            }
            var fn = DRACOWorker.toString();
            var body = ["/* draco decoder */", jsContent, "", "/* worker */", fn.substring(fn.indexOf("{") + 1, fn.lastIndexOf("}"))].join("\n");
            this.workerSourceURL = URL.createObjectURL(new Blob([body]));
        });
        return this.decoderPending;
    }

    public function _getWorker(taskID: Int, taskCost: Int): Promise<Void> {
        return this._initDecoder().then(function() {
            if (this.workerPool.length < this.workerLimit) {
                var worker = new Worker(this.workerSourceURL);
                worker._callbacks = { };
                worker._taskCosts = { };
                worker._taskLoad = 0;
                worker.postMessage({
                    "type": "init",
                    "decoderConfig": this.decoderConfig
                });
                worker.onmessage = function(e) {
                    var message = e.data;
                    switch (message.type) {
                        case "decode":
                            worker._callbacks[message.id].resolve(message);
                            break;
                        case "error":
                            worker._callbacks[message.id].reject(message);
                            break;
                        default:
                            trace("THREE.DRACOLoader: Unexpected message, \"" + message.type + "\"");
                    }
                };
                this.workerPool.push(worker);
            } else {
                this.workerPool.sort(function(a, b) {
                    return a._taskLoad > b._taskLoad ? -1 : 1;
                });
            }
            var worker1 = this.workerPool[this.workerPool.length - 1];
            worker1._taskCosts[taskID] = taskCost;
            worker1._taskLoad += taskCost;
            return worker1;
        });
    }

    public function _releaseTask(worker: Worker, taskID: Int): Void {
        worker._taskLoad -= worker._taskCosts[taskID];
        delete worker._callbacks[taskID];
        delete worker._taskCosts[taskID];
    }

    public function debug(): Void {
        trace("Task load: ", this.workerPool.map(function(worker) {
            return worker._taskLoad;
        }));
    }

    public function dispose(): DRACOLoader {
        var _g = 0;
        while (_g < this.workerPool.length) {
            var i = _g++;
            this.workerPool[i].terminate();
        }
        this.workerPool.length = 0;
        if (this.workerSourceURL != "") {
            URL.revokeObjectURL(this.workerSourceURL);
        }
        return this;
    }
}

class DRACOWorker {
    static function new() {
        var decoderConfig;
        var decoderPending;
        onmessage = function(e) {
            var message = e.data;
            switch (message.type) {
                case "init":
                    decoderConfig = message.decoderConfig;
                    decoderPending = new Promise(function(resolve, _) {
                        decoderConfig.onModuleLoaded = function(draco) {
                            resolve({
                                "draco": draco
                            });
                        };
                        DracoDecoderModule(decoderConfig);
                    });
                    break;
                case "decode":
                    var buffer = message.buffer;
                    var taskConfig = message.taskConfig;
                    decoderPending.then(function(module) {
                        var draco = module.draco;
                        var decoder = new draco.Decoder();
                        try {
                            var geometry = decodeGeometry(draco, decoder, new Int8Array(buffer), taskConfig);
                            var buffers = geometry.attributes.map(function(attr) {
                                return attr.array.buffer;
                            });
                            if (geometry.index != null) {
                                buffers.push(geometry.index.array.buffer);
                            }
                            self.postMessage({
                                "type": "decode",
                                "id": message.id,
                                "geometry": geometry
                            }, buffers);
                        } catch (error) {
                            trace(error);
                            self.postMessage({
                                "type": "error",
                                "id": message.id,
                                "error": error.message
                            });
                        } finally {
                            draco.destroy(decoder);
                        }
                    });
                    break;
            }
        };
        function decodeGeometry(draco, decoder, array, taskConfig) {
            var attributeIDs = taskConfig.attributeIDs;
            var attributeTypes = taskConfig.attributeTypes;
            var dracoGeometry;
            var decodingStatus;
            var geometryType = decoder.GetEncodedGeometryType(array);
            if (geometryType == draco.TRIANGULAR_MESH) {
                dracoGeometry = new draco.Mesh();
                decodingStatus = decoder.DecodeArrayToMesh(array, array.byteLength, dracoGeometry);
            } else if (geometryType == draco.POINT_CLOUD) {
                dracoGeometry = new draco.PointCloud();
                decodingStatus = decoder.DecodeArrayToPointCloud(array, array.byteLength, dracoGeometry);
            } else {
                throw new Error("THREE.DRACOLoader: Unexpected geometry type.");
            }
            if (!decodingStatus.ok() || dracoGeometry.ptr == 0) {
                throw new Error("THREE.DRACOLoader: Decoding failed: " + decodingStatus.error_msg());
            }
            var geometry = {
                "index": null,
                "attributes": []
            };
            var _g = 0;
            var _g1 = Reflect.fields(attributeIDs);
            while (_g < _g1.length) {
                var attributeName = _g1[_g];
                ++_g;
                var attributeType = self[attributeTypes[attributeName]];
                var attribute;
                var attributeID;
                if (taskConfig.useUniqueIDs) {
                    attributeID = attributeIDs[attributeName];
                    attribute = decoder.GetAttributeByUniqueId(dracoGeometry, attributeID);
                } else {
                    attributeID = decoder.GetAttributeId(dracoGeometry, draco[attributeIDs[attributeName]]);
                    if (attributeID == -1) {
                        continue;
                    }
                    attribute = decoder.GetAttribute(dracoGeometry, attributeID);
                }
                var attributeResult = decodeAttribute(draco, decoder, dracoGeometry, attributeName, attributeType, attribute);
                if (attributeName == "color") {
                    attributeResult.vertexColorSpace = taskConfig.vertexColorSpace;
                }
                geometry.attributes.push(attributeResult);
            }
            if (geometryType == draco.TRIANGULAR_MESH) {
                geometry.index = decodeIndex(draco, decoder, dracoGeometry);
            }
            draco.destroy(dracoGeometry);
            return geometry;
        }
        function decodeIndex(draco, decoder, dracoGeometry) {
            var numFaces = dracoGeometry.num_faces();
            var numIndices = numFaces * 3;
            var byteLength = numIndices * 4;
            var ptr = draco._malloc(byteLength);
            decoder.GetTrianglesUInt32Array(dracoGeometry, byteLength, ptr);
            var index = new Uint32Array(draco.HEAPF32.buffer, ptr, numIndices).slice();
            draco._free(ptr);
            return {
                "array": index,
                "itemSize": 1
            };
        }
        function decodeAttribute(draco, decoder, dracoGeometry, attributeName, attributeType, attribute) {
            var numComponents = attribute.num_components();
            var numPoints = dracoGeometry.num_points();
            var numValues = numPoints * numComponents;
            var byteLength = numValues * attributeType.BYTES_PER_ELEMENT;
            var dataType = getDracoDataType(draco, attributeType);
            var ptr = draco._malloc(byteLength);
            decoder.GetAttributeDataArrayForAllPoints(dracoGeometry, attribute, dataType, byteLength, ptr);
            var array = new attributeType(draco.HEAPF32.buffer, ptr, numValues).slice();
            draco._free(ptr);
            return {
                "name": attributeName,
                "array": array,
                "itemSize": numComponents
            };
        }
        function getDracoDataType(draco, attributeType) {
            switch (attributeType) {
                case Float32Array:
                    return draco.DT_FLOAT32;
                case Int8Array:
                    return draco.DT_INT8;
                case Int16Array:
                    return draco.DT_INT16;
                case Int32Array:
                    return draco.DT_INT32;
                case Uint8Array:
                    return draco.DT_UINT8;
                case Uint16Array:
                    return draco.DT_UINT16;
                case Uint32Array:
                    return draco.DT_UINT32;
            }
        }
    }
}