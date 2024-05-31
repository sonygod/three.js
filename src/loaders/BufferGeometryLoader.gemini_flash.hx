import three.math.Sphere;
import three.math.Vector3;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.core.InstancedBufferGeometry;
import three.core.InstancedBufferAttribute;
import three.core.InterleavedBufferAttribute;
import three.core.InterleavedBuffer;
import three.utils.Utils;

class BufferGeometryLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(js.JSON.parse(text)));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(json:Dynamic):BufferGeometry {
		var interleavedBufferMap:Map<String, InterleavedBuffer> = new Map();
		var arrayBufferMap:Map<String, haxe.io.Bytes> = new Map();

		function getInterleavedBuffer(json:Dynamic, uuid:String):InterleavedBuffer {
			if (interleavedBufferMap.exists(uuid)) {
				return interleavedBufferMap.get(uuid);
			}
			var interleavedBuffers:Dynamic = json.interleavedBuffers;
			var interleavedBuffer:Dynamic = interleavedBuffers[uuid];
			var buffer:haxe.io.Bytes = getArrayBuffer(json, interleavedBuffer.buffer);
			var array:Array<Float> = Utils.getTypedArray(interleavedBuffer.type, buffer);
			var ib = new InterleavedBuffer(array, interleavedBuffer.stride);
			ib.uuid = interleavedBuffer.uuid;
			interleavedBufferMap.set(uuid, ib);
			return ib;
		}

		function getArrayBuffer(json:Dynamic, uuid:String):haxe.io.Bytes {
			if (arrayBufferMap.exists(uuid)) {
				return arrayBufferMap.get(uuid);
			}
			var arrayBuffers:Dynamic = json.arrayBuffers;
			var arrayBuffer:Dynamic = arrayBuffers[uuid];
			var ab:haxe.io.Bytes = new haxe.io.Bytes(new Uint32Array(arrayBuffer)).toBytes();
			arrayBufferMap.set(uuid, ab);
			return ab;
		}

		var geometry:BufferGeometry = json.isInstancedBufferGeometry ? new InstancedBufferGeometry() : new BufferGeometry();
		var index:Dynamic = json.data.index;

		if (index != null) {
			var typedArray:Array<Float> = Utils.getTypedArray(index.type, index.array);
			geometry.setIndex(new BufferAttribute(typedArray, 1));
		}

		var attributes:Dynamic = json.data.attributes;

		for (key in attributes) {
			var attribute:Dynamic = attributes[key];
			var bufferAttribute:BufferAttribute;

			if (attribute.isInterleavedBufferAttribute) {
				var interleavedBuffer:InterleavedBuffer = getInterleavedBuffer(json.data, attribute.data);
				bufferAttribute = new InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
			} else {
				var typedArray:Array<Float> = Utils.getTypedArray(attribute.type, attribute.array);
				var bufferAttributeConstr:Dynamic = attribute.isInstancedBufferAttribute ? InstancedBufferAttribute : BufferAttribute;
				bufferAttribute = new bufferAttributeConstr(typedArray, attribute.itemSize, attribute.normalized);
			}

			if (attribute.name != null) bufferAttribute.name = attribute.name;
			if (attribute.usage != null) bufferAttribute.setUsage(attribute.usage);

			geometry.setAttribute(key, bufferAttribute);
		}

		var morphAttributes:Dynamic = json.data.morphAttributes;

		if (morphAttributes != null) {
			for (key in morphAttributes) {
				var attributeArray:Array<Dynamic> = morphAttributes[key];
				var array:Array<BufferAttribute> = [];

				for (i in 0...attributeArray.length) {
					var attribute:Dynamic = attributeArray[i];
					var bufferAttribute:BufferAttribute;

					if (attribute.isInterleavedBufferAttribute) {
						var interleavedBuffer:InterleavedBuffer = getInterleavedBuffer(json.data, attribute.data);
						bufferAttribute = new InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
					} else {
						var typedArray:Array<Float> = Utils.getTypedArray(attribute.type, attribute.array);
						bufferAttribute = new BufferAttribute(typedArray, attribute.itemSize, attribute.normalized);
					}

					if (attribute.name != null) bufferAttribute.name = attribute.name;
					array.push(bufferAttribute);
				}
				geometry.morphAttributes[key] = array;
			}
		}

		var morphTargetsRelative:Bool = json.data.morphTargetsRelative;

		if (morphTargetsRelative) {
			geometry.morphTargetsRelative = true;
		}

		var groups:Dynamic = json.data.groups || json.data.drawcalls || json.data.offsets;

		if (groups != null) {
			for (i in 0...groups.length) {
				var group:Dynamic = groups[i];
				geometry.addGroup(group.start, group.count, group.materialIndex);
			}
		}

		var boundingSphere:Dynamic = json.data.boundingSphere;

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