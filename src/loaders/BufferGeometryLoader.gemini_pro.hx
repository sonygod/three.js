import js.html.File;
import js.html.FileReader;
import js.html.XMLHttpRequest;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.InstancedBufferAttribute;
import three.core.InstancedBufferGeometry;
import three.core.InterleavedBuffer;
import three.core.InterleavedBufferAttribute;
import three.math.Sphere;
import three.math.Vector3;
import three.utils.TypedArrayUtils;
import three.loaders.Loader;

class BufferGeometryLoader extends Loader {

	public function new(manager:Loader = null) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(js.Json.parse(text)));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					js.Lib.console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(json:Dynamic):BufferGeometry {
		var interleavedBufferMap:Map<String, InterleavedBuffer> = new Map();
		var arrayBufferMap:Map<String, js.html.ArrayBuffer> = new Map();

		function getInterleavedBuffer(json:Dynamic, uuid:String):InterleavedBuffer {
			if (interleavedBufferMap.exists(uuid)) return interleavedBufferMap.get(uuid);
			var interleavedBuffers = json.interleavedBuffers;
			var interleavedBuffer = interleavedBuffers[uuid];
			var buffer = getArrayBuffer(json, interleavedBuffer.buffer);
			var array = TypedArrayUtils.getTypedArray(interleavedBuffer.type, buffer);
			var ib = new InterleavedBuffer(array, interleavedBuffer.stride);
			ib.uuid = interleavedBuffer.uuid;
			interleavedBufferMap.set(uuid, ib);
			return ib;
		}

		function getArrayBuffer(json:Dynamic, uuid:String):js.html.ArrayBuffer {
			if (arrayBufferMap.exists(uuid)) return arrayBufferMap.get(uuid);
			var arrayBuffers = json.arrayBuffers;
			var arrayBuffer = arrayBuffers[uuid];
			var ab = new js.html.Uint32Array(arrayBuffer).buffer;
			arrayBufferMap.set(uuid, ab);
			return ab;
		}

		var geometry = (json.isInstancedBufferGeometry) ? new InstancedBufferGeometry() : new BufferGeometry();

		var index = json.data.index;

		if (index != null) {
			var typedArray = TypedArrayUtils.getTypedArray(index.type, index.array);
			geometry.setIndex(new BufferAttribute(typedArray, 1));
		}

		var attributes = json.data.attributes;

		for (key in attributes) {
			var attribute = attributes[key];
			var bufferAttribute:BufferAttribute;

			if (attribute.isInterleavedBufferAttribute) {
				var interleavedBuffer = getInterleavedBuffer(json.data, attribute.data);
				bufferAttribute = new InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
			} else {
				var typedArray = TypedArrayUtils.getTypedArray(attribute.type, attribute.array);
				var bufferAttributeConstr = (attribute.isInstancedBufferAttribute) ? InstancedBufferAttribute : BufferAttribute;
				bufferAttribute = new bufferAttributeConstr(typedArray, attribute.itemSize, attribute.normalized);
			}

			if (attribute.name != null) bufferAttribute.name = attribute.name;
			if (attribute.usage != null) bufferAttribute.setUsage(attribute.usage);

			geometry.setAttribute(key, bufferAttribute);
		}

		var morphAttributes = json.data.morphAttributes;

		if (morphAttributes != null) {
			for (key in morphAttributes) {
				var attributeArray = morphAttributes[key];
				var array:Array<BufferAttribute> = [];

				for (i in 0...attributeArray.length) {
					var attribute = attributeArray[i];
					var bufferAttribute:BufferAttribute;

					if (attribute.isInterleavedBufferAttribute) {
						var interleavedBuffer = getInterleavedBuffer(json.data, attribute.data);
						bufferAttribute = new InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
					} else {
						var typedArray = TypedArrayUtils.getTypedArray(attribute.type, attribute.array);
						bufferAttribute = new BufferAttribute(typedArray, attribute.itemSize, attribute.normalized);
					}

					if (attribute.name != null) bufferAttribute.name = attribute.name;
					array.push(bufferAttribute);
				}

				geometry.morphAttributes[key] = array;
			}
		}

		var morphTargetsRelative = json.data.morphTargetsRelative;

		if (morphTargetsRelative) {
			geometry.morphTargetsRelative = true;
		}

		var groups = json.data.groups || json.data.drawcalls || json.data.offsets;

		if (groups != null) {
			for (i in 0...groups.length) {
				var group = groups[i];
				geometry.addGroup(group.start, group.count, group.materialIndex);
			}
		}

		var boundingSphere = json.data.boundingSphere;

		if (boundingSphere != null) {
			var center = new Vector3();

			if (boundingSphere.center != null) {
				center.fromArray(boundingSphere.center);
			}

			geometry.boundingSphere = new Sphere(center, boundingSphere.radius);
		}

		if (json.name != null) geometry.name = json.name;
		if (json.userData != null) geometry.userData = json.userData;

		return geometry;
	}
}

class FileLoader extends Loader {

	public function new(manager:Loader = null) {
		super(manager);
	}

	public function load(url:String, onLoad:String->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var request = new XMLHttpRequest();
		request.onload = function(e:Dynamic) {
			onLoad(request.responseText);
		};

		request.onerror = function(e:Dynamic) {
			if (onError != null) {
				onError(e);
			} else {
				js.Lib.console.error(e);
			}
			this.manager.itemError(url);
		};

		request.onprogress = function(e:Dynamic) {
			if (onProgress != null) {
				onProgress(e);
			}
		};

		request.open("GET", url, true);
		request.send();
	}
}