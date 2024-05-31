package ;

import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.math.Color;
import js.lib.Promise;
import js.lib.Uint8Array;
import js.lib.ArrayBuffer;
import js.lib.URL;
import js.lib.Blob;
import js.lib.Float32Array;
import js.lib.Int8Array;
import js.lib.Int16Array;
import js.lib.Int32Array;
import js.lib.Uint16Array;
import js.lib.Uint32Array;
import js.lib.WebAssembly;
import three.Three;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;

@:enum
private abstract DracoGeometryType(Int) {
  var TRIANGULAR_MESH = 0;
  var POINT_CLOUD = 1;
}

@:enum
private abstract DracoDataType(Int) {
	var DT_INT8 = 0;
	var DT_UINT8 = 1;
	var DT_INT16 = 2;
	var DT_UINT16 = 3;
	var DT_INT32 = 4;
	var DT_UINT32 = 5;
	var DT_FLOAT32 = 6;
}

typedef DracoDecoderConfig = {
  ?onModuleLoaded : Dynamic -> Void,
  ?wasmBinary: ArrayBuffer
}

@:native("DracoDecoderModule") extern class DracoDecoderModule {}

@:native("self") extern class WorkerSelf {
  public var onmessage: (e: Dynamic) -> Void;
  public function postMessage(message: Dynamic, ?transfer: Array<Dynamic>): Void;
}

@:native("Worker")
class HaxeWorker {
	public var _callbacks:  Map<Int, { resolve : Dynamic -> Void, reject : Dynamic -> Void}>;
	public var _taskCosts: Map<Int, Int>;
	public var _taskLoad: Int;

  public function new(string: String) { }

	public function terminate():Void {}
}

class DRACOLoader extends Loader {

	public var decoderPath(default, set):String;

	public var decoderConfig(default, set):DracoDecoderConfig;

	public var decoderBinary: Null<Dynamic>;

	public var decoderPending: Null<Promise<Dynamic>>;

	public var workerLimit(default, set):Int;

	public var workerPool(default, default):Array<HaxeWorker>;

	public var workerNextTaskID(default, null):Int;

	public var workerSourceURL(default, null):String;

	public var defaultAttributeIDs(default, null):{ position: String, normal: String, color: String, uv: String };

	public var defaultAttributeTypes(default, null):{ position: String, normal: String, color: String, uv: String };

	public function new(manager: Loader.LoaderManager = null) {
		super(manager);
		this.decoderPath = '';
		this.decoderConfig = { };
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
	}

	public function setDecoderPath(path:String):DRACOLoader {
		this.decoderPath = path;
		return this;
	}

	public function setDecoderConfig(config:DracoDecoderConfig):DRACOLoader {
		this.decoderConfig = config;
		return this;
	}

	public function setWorkerLimit(workerLimit:Int):DRACOLoader {
		this.workerLimit = workerLimit;
		return this;
	}

	override public function load(url:String, onLoad: BufferGeometry->Void, ?onProgress: Int->Void, ?onError: String->Void):Void {
		final loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url,
			(buffer: ArrayBuffer) -> this.parse(buffer, onLoad, onError),
			onProgress,
			onError
		);
	}

	public function parse(buffer: ArrayBuffer, onLoad: BufferGeometry->Void, ?onError: String->Void):Void {
		this.decodeDracoFile(buffer, onLoad, null, null, SRGBColorSpace, onError).catch(function (e) {
			if (onError != null)
				onError(e);
			return null;
		});
	}

	public function decodeDracoFile(
		buffer: ArrayBuffer,
		?callback: BufferGeometry->Void,
		attributeIDs: Dynamic = null,
		attributeTypes: Dynamic = null,
		vertexColorSpace: Int = LinearSRGBColorSpace,
		?onError: String->Void
	): Promise<Dynamic> {
		final taskConfig = {
			attributeIDs: (attributeIDs != null ? attributeIDs : this.defaultAttributeIDs),
			attributeTypes: (attributeTypes != null ? attributeTypes : this.defaultAttributeTypes),
			useUniqueIDs: (attributeIDs != null),
			vertexColorSpace: vertexColorSpace
		};
		return this.decodeGeometry(buffer, taskConfig).then(function (geometry) {
			if (callback != null)
				callback(geometry);
			return geometry;
		}).catch(function (e) {
			if (onError != null)
				onError(e);
			return null;
		});
	}

	public function decodeGeometry(buffer: ArrayBuffer, taskConfig: Dynamic): Promise<BufferGeometry> {
		final taskKey = JSON.stringify(taskConfig);
		if (Three.getCache().has(buffer)) {
			final cachedTask = Three.getCache().get(buffer);
			if (cachedTask.key == taskKey) {
				return cachedTask.promise;
			} else if (buffer.byteLength == 0) {
				throw new js.lib.Error(
					'THREE.DRACOLoader: Unable to re-decode a buffer with different ' +
					'settings. Buffer has already been transferred.'
				);
			}
		}
		var worker:HaxeWorker = null;
		final taskID:Int = this.workerNextTaskID++;
		final taskCost:Int = buffer.byteLength;

		final geometryPending = this._getWorker(taskID, taskCost)
		.then((_worker: HaxeWorker) -> {
			worker = _worker;
			return new Promise((resolve, reject) -> {
				worker._callbacks[taskID] = { resolve: resolve, reject: reject };
				worker.postMessage({ type: 'decode', id: taskID, taskConfig: taskConfig, buffer: buffer }, [buffer]);
			});
		})
		.then((message: Dynamic) -> this._createGeometry(message.geometry));
		geometryPending
			.catch((_) -> true)
			.then((_) -> {
				if (worker != null && taskID != 0) {
					this._releaseTask(worker, taskID);
				}
			});
		Three.getCache().set(buffer, {
			key: taskKey,
			promise: geometryPending
		});
		return geometryPending;
	}

	function _createGeometry(geometryData: Dynamic):BufferGeometry {
		final geometry = new BufferGeometry();
		if (geometryData.index != null) {
			geometry.setIndex(new BufferAttribute(new Uint32Array(geometryData.index.array), 1));
		}
		for (i in 0...geometryData.attributes.length) {
			final result = geometryData.attributes[i];
			final name:String = result.name;
			final array = (result.array : ArrayBuffer);
			final itemSize:Int = result.itemSize;
			final attribute = new BufferAttribute((array : Dynamic), itemSize);
			if (name == 'color') {
				this._assignVertexColorSpace(attribute, result.vertexColorSpace);
				// TODO: revisit
				// attribute.normalized = (array instanceof Float32Array) == false;
			}
			geometry.setAttribute(name, attribute);
		}
		return geometry;
	}

	function _assignVertexColorSpace(attribute:BufferAttribute, inputColorSpace:Int):Void {
		if (inputColorSpace != SRGBColorSpace) {
			return;
		}
		final _color = new Color();
		for (i in 0...attribute.count) {
			_color.fromBufferAttribute(attribute, i).convertSRGBToLinear();
			attribute.setXYZ(i, _color.r, _color.g, _color.b);
		}
	}

	function _loadLibrary(url:String, responseType:String):Promise<Dynamic> {
		final loader = new FileLoader(this.manager);
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

	function _initDecoder():Promise<Dynamic> {
		if (this.decoderPending != null) {
			return this.decoderPending;
		}
		final useJS = (WebAssembly == null) || (this.decoderConfig.type == 'js');
		final librariesPending = [];
		if (useJS) {
			librariesPending.push(this._loadLibrary('draco_decoder.js', 'text'));
		} else {
			librariesPending.push(this._loadLibrary('draco_wasm_wrapper.js', 'text'));
			librariesPending.push(this._loadLibrary('draco_decoder.wasm', 'arraybuffer'));
		}
		this.decoderPending = Promise.all(librariesPending).then((libraries: Array<Dynamic>) -> {
			final jsContent:String = libraries[0];
			if (!useJS) {
				this.decoderConfig.wasmBinary = libraries[1];
			}
			final fn = js.Lib.reify(DRACOWorker).toString();
			final body = [
				'/* draco decoder */',
				jsContent,
				'',
				'/* worker */',
				fn.substring(fn.indexOf('{') + 1, fn.lastIndexOf('}'))
			].join('\n');
			this.workerSourceURL = URL.createObjectURL(new Blob([body]));
		});
		return this.decoderPending;
	}

	function _getWorker(taskID: Int, taskCost: Int): Promise<HaxeWorker> {
		return this._initDecoder().then((_) -> {
			if (this.workerPool.length < this.workerLimit) {
				final worker = new HaxeWorker(this.workerSourceURL);
				worker._callbacks = new Map();
				worker._taskCosts = new Map();
				worker._taskLoad = 0;
				worker.postMessage({ type: 'init', decoderConfig: this.decoderConfig });
				worker.onmessage = function (e: { data : Dynamic }) {
					final message = e.data;
					switch (message.type) {
						case 'decode':
							worker._callbacks[message.id].resolve(message);
						case 'error':
							worker._callbacks[message.id].reject(message);
						case _:
							trace('THREE.DRACOLoader: Unexpected message, ${message.type}');
					}
				};
				this.workerPool.push(worker);
			} else {
				this.workerPool.sort(function (a: HaxeWorker, b: HaxeWorker) {
					if (a._taskLoad > b._taskLoad) {
						return -1;
					} else if (a._taskLoad < b._taskLoad) {
						return 1;
					} else {
						return 0;
					}
				});
			}
			final worker:HaxeWorker = this.workerPool[this.workerPool.length - 1];
			worker._taskCosts[taskID] = taskCost;
			worker._taskLoad += taskCost;
			return worker;
		});
	}

	function _releaseTask(worker: HaxeWorker, taskID: Int): Void {
		worker._taskLoad -= worker._taskCosts[taskID];
		worker._callbacks.remove(taskID);
		worker._taskCosts.remove(taskID);
	}

	public function debug():Void {
		trace('Task load:', this.workerPool.map(function (worker) {
			return worker._taskLoad;
		}));
	}

	override public function dispose():DRACOLoader {
		for (i in 0...this.workerPool.length) {
			this.workerPool[i].terminate();
		}
		this.workerPool = [];
		if (this.workerSourceURL != '') {
			URL.revokeObjectURL(this.workerSourceURL);
		}
		return this;
	}

	function set_decoderPath(value:String):String {
		this.decoderPath = value;
		return this.decoderPath;
	}

	function set_decoderConfig(value:DracoDecoderConfig):DracoDecoderConfig {
		this.decoderConfig = value;
		return this.decoderConfig;
	}

	function set_workerLimit(value:Int):Int {
		this.workerLimit = value;
		return this.workerLimit;
	}

}

private function DRACOWorker(): Void {
	var decoderConfig: DracoDecoderConfig = null;
	var decoderPending: Promise<Dynamic> = null;

	(cast (this: WorkerSelf)).onmessage = function (e: { data: Dynamic }): Void {
		final message = e.data;
		switch (message.type) {
			case 'init':
				decoderConfig = message.decoderConfig;
				decoderPending = new Promise(function (resolve, _) {
					decoderConfig.onModuleLoaded = function (draco: Dynamic): Void {
						resolve({ draco: draco });
					};
					final dracoDecoderModule: DracoDecoderModule = new DracoDecoderModule();
					dracoDecoderModule(decoderConfig);
				});
			case 'decode':
				final buffer = (message.buffer : ArrayBuffer);
				final taskConfig: Dynamic = message.taskConfig;
				if (decoderPending != null)
				{
					decoderPending.then(function (module: Dynamic): Void {
						final draco = module.draco;
						final decoder = new draco.Decoder();
						try {
							final geometry = decodeGeometry(draco, decoder, new Int8Array(buffer), taskConfig);
							final buffers = geometry.attributes.map(function (attr: Dynamic): ArrayBuffer {
								return attr.array.buffer;
							});
							if (geometry.index != null) {
								buffers.push(geometry.index.array.buffer);
							}
							(cast (this: WorkerSelf)).postMessage({ type: 'decode', id: message.id, geometry: geometry }, buffers);
						} catch (error: Dynamic) {
							trace(error);
							(cast (this: WorkerSelf)).postMessage({ type: 'error', id: message.id, error: error.message });
						} finally {
							draco.destroy(decoder);
						}
					});
				}
			case _:
		}
	};

	function decodeGeometry(draco: Dynamic, decoder: Dynamic, array: Int8Array, taskConfig: Dynamic): Dynamic {
		final attributeIDs: Dynamic = taskConfig.attributeIDs;
		final attributeTypes: Dynamic = taskConfig.attributeTypes;
		var dracoGeometry: Dynamic = null;
		var decodingStatus: Dynamic = null;
		final geometryType: Int = decoder.GetEncodedGeometryType(array);
		if (geometryType == DracoGeometryType.TRIANGULAR_MESH) {
			dracoGeometry = new draco.Mesh();
			decodingStatus = decoder.DecodeArrayToMesh(array, array.byteLength, dracoGeometry);
		} else if (geometryType == DracoGeometryType.POINT_CLOUD) {
			dracoGeometry = new draco.PointCloud();
			decodingStatus = decoder.DecodeArrayToPointCloud(array, array.byteLength, dracoGeometry);
		} else {
			throw new js.lib.Error('THREE.DRACOLoader: Unexpected geometry type.');
		}
		if (!decodingStatus.ok() || dracoGeometry.ptr == 0) {
			throw new js.lib.Error('THREE.DRACOLoader: Decoding failed: ${decodingStatus.error_msg()}');
		}
		final geometry: Dynamic = { index: null, attributes: [] };
		for (attributeName in Reflect.fields(attributeIDs)) {
			final attributeType: String = Reflect.field(attributeTypes, attributeName);
			var attribute: Dynamic = null;
			var attributeID: Dynamic = null;
			if (taskConfig.useUniqueIDs) {
				attributeID = Reflect.field(attributeIDs, attributeName);
				attribute = decoder.GetAttributeByUniqueId(dracoGeometry, attributeID);
			} else {
				attributeID = decoder.GetAttributeId(dracoGeometry, draco[Reflect.field(attributeIDs, attributeName)]);
				if (attributeID == -1) {
					continue;
				}
				attribute = decoder.GetAttribute(dracoGeometry, attributeID);
			}
			final attributeResult: Dynamic = decodeAttribute(draco, decoder, dracoGeometry, attributeName, (cast (js.Lib.global : Dynamic))[attributeType], attribute);
			if (attributeName == 'color') {
				attributeResult.vertexColorSpace = taskConfig.vertexColorSpace;
			}
			geometry.attributes.push(attributeResult);
		}
		if (geometryType == DracoGeometryType.TRIANGULAR_MESH) {
			geometry.index = decodeIndex(draco, decoder, dracoGeometry);
		}
		draco.destroy(dracoGeometry);
		return geometry;
	}

	function decodeIndex(draco: Dynamic, decoder: Dynamic, dracoGeometry: Dynamic): Dynamic {
		final numFaces: Int = dracoGeometry.num_faces();
		final numIndices: Int = numFaces * 3;
		final byteLength: Int = numIndices * 4;
		final ptr: Int = draco._malloc(byteLength);
		decoder.GetTrianglesUInt32Array(dracoGeometry, byteLength, ptr);
		final index = new Uint32Array(draco.HEAPF32.buffer, ptr, numIndices).slice();
		draco._free(ptr);
		return { array: index, itemSize: 1 };
	}

	function decodeAttribute(draco: Dynamic, decoder: Dynamic, dracoGeometry: Dynamic, attributeName: String, attributeType: Dynamic, attribute: Dynamic): Dynamic {
		final numComponents: Int = attribute.num_components();
		final numPoints: Int = dracoGeometry.num_points();
		final numValues: Int = numPoints * numComponents;
		final byteLength: Int = numValues * attributeType.BYTES_PER_ELEMENT;
		final dataType: Int = getDracoDataType(draco, attributeType);
		final ptr: Int = draco._malloc(byteLength);
		decoder.GetAttributeDataArrayForAllPoints(dracoGeometry, attribute, dataType, byteLength, ptr);

		final array = switch attributeType {
      case Float32Array: new Float32Array(draco.HEAPF32.buffer, ptr, numValues).slice();
      case Int8Array: new Int8Array(draco.HEAPF32.buffer, ptr, numValues).slice();
      case Int16Array: new Int16Array(draco.HEAPF32.buffer, ptr, numValues).slice();
      case Int32Array: new Int32Array(draco.HEAPF32.buffer, ptr, numValues).slice();
      case Uint8Array: new Uint8Array(draco.HEAPF32.buffer, ptr, numValues).slice();
      case Uint16Array: new Uint16Array(draco.HEAPF32.buffer, ptr, numValues).slice();
      case Uint32Array: new Uint32Array(draco.HEAPF32.buffer, ptr, numValues).slice();
      case _: throw new js.lib.Error("unknown attribute type");
    };

		draco._free(ptr);
		return {
			name: attributeName,
			array: array,
			itemSize: numComponents
		};
	}

	function getDracoDataType(draco: Dynamic, attributeType: Dynamic): Int {
		switch (attributeType) {
			case Float32Array: return DracoDataType.DT_FLOAT32;
			case Int8Array: return DracoDataType.DT_INT8;
			case Int16Array: return DracoDataType.DT_INT16;
			case Int32Array: return DracoDataType.DT_INT32;
			case Uint8Array: return DracoDataType.DT_UINT8;
			case Uint16Array: return DracoDataType.DT_UINT16;
			case Uint32Array: return DracoDataType.DT_UINT32;
			case _: throw new js.lib.Error('THREE.DRACOLoader: Unsupported attribute type.');
		}
	}
}