import haxe.io.Bytes;

class BufferGeometryLoader extends Loader {
	public function new(manager:LoadingManager) {
		super(manager);
	}

	public function load(url:String, onLoad:BufferGeometry -> Void, onProgress:Float -> Void, onError:String -> Void):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.path = scope.path;
		loader.requestHeader = scope.requestHeader;
		loader.withCredentials = scope.withCredentials;
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(JSON.parse(text)));
			} catch (e) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	private function parse(json:Dynamic):BufferGeometry {
		var interleavedBufferMap = {};
		var arrayBufferMap = {};

		function getInterleavedBuffer(json:Dynamic, uuid:Int):InterleavedBuffer {
			if (interleavedBufferMap.exists(uuid)) {
				return interleavedBufferMap.get(uuid);
			}

			var interleavedBuffers = json.interleavedBuffers;
			var interleavedBuffer = interleavedBuffers[uuid];

			var buffer = getArrayBuffer(json, interleavedBuffer.buffer);

			var array = getTypedArray(interleavedBuffer.type, buffer);
			var ib = new InterleavedBuffer(array, interleavedBuffer.stride);
			ib.uuid = interleavedBuffer.uuid;

			interleavedBufferMap.set(uuid, ib);

			return ib;
		}

		function getArrayBuffer(json:Dynamic, uuid:Int):Bytes {
			if (arrayBufferMap.exists(uuid)) {
				return arrayBufferMap.get(uuid);
			}

			var arrayBuffers = json.arrayBuffers;
			var arrayBuffer = arrayBuffers[uuid];

			var ab = new Bytes(new Uint32Array(arrayBuffer).buffer);

			arrayBufferMap.set(uuid, ab);

			return ab;
		}

		var geometry:BufferGeometry;
		if (Std.is(json.isInstancedBufferGeometry, Bool)) {
			geometry = new InstancedBufferGeometry();
		} else {
			geometry = new BufferGeometry();
		}

		var index = json.data.index;

		if (index != null) {
			var typedArray = getTypedArray(index.type, index.array);
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
				var typedArray = getTypedArray(attribute.type, attribute.array);
				var bufferAttributeConstr:Dynamic;
				if (Std.is(attribute.isInstancedBufferAttribute, Bool)) {
					bufferAttributeConstr = InstancedBufferAttribute;
				} else {
					bufferAttributeConstr = BufferAttribute;
				}
				bufferAttribute = new bufferAttributeConstr(typedArray, attribute.itemSize, attribute.normalized);
			}

			if (attribute.name != null) {
				bufferAttribute.name = attribute.name;
			}
			if (attribute.usage != null) {
				bufferAttribute.setUsage(attribute.usage);
			}

			geometry.setAttribute(key, bufferAttribute);
		}

		var morphAttributes = json.data.morphAttributes;

		if (morphAttributes != null) {
			for (key in morphAttributes) {
				var attributeArray = morphAttributes[key];

				var array = [];

				var i = 0;
				while (i < attributeArray.length) {
					var attribute = attributeArray[i++];
					var bufferAttribute:BufferAttribute;

					if (attribute.isInterleavedBufferAttribute) {
						var interleavedBuffer = getInterleavedBuffer(json.data, attribute.data);
						bufferAttribute = new InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
					} else {
						var typedArray = getTypedArray(attribute.type, attribute.array);
						bufferAttribute = new BufferAttribute(typedArray, attribute.itemSize, attribute.normalized);
					}

					if (attribute.name != null) {
						bufferAttribute.name = attribute.name;
					}
					array.push(bufferAttribute);
				}

				geometry.morphAttributes.set(key, array);
			}
		}

		var morphTargetsRelative = json.data.morphTargetsRelative;

		if (morphTargetsRelative) {
			geometry.morphTargetsRelative = true;
		}

		var groups = json.data.groups;
		if (groups == null) groups = json.data.drawcalls;
		if (groups == null) groups = json.data.offsets;

		if (groups != null) {
			var i = 0;
			while (i < groups.length) {
				var group = groups[i++];

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

		if (json.name != null) {
			geometry.name = json.name;
		}
		if (json.userData != null) {
			geometry.userData = json.userData;
		}

		return geometry;
	}
}