import three.core.BufferAttribute;
import three.utils.Utils;

class WebGLGeometries {

	private var gl:WebGLRenderingContext;
	private var attributes:BufferAttribute;
	private var info:Dynamic;
	private var bindingStates:Dynamic;

	private var geometries:haxe.ds.StringMap<Bool> = new haxe.ds.StringMap();
	private var wireframeAttributes:haxe.ds.WeakMap<BufferAttribute> = new haxe.ds.WeakMap();

	public function new(gl:WebGLRenderingContext, attributes:BufferAttribute, info:Dynamic, bindingStates:Dynamic) {
		this.gl = gl;
		this.attributes = attributes;
		this.info = info;
		this.bindingStates = bindingStates;
	}

	private function onGeometryDispose(event:Event) {
		var geometry = event.target;

		if (geometry.index != null) {
			attributes.remove(geometry.index);
		}

		for (name in Reflect.fields(geometry.attributes)) {
			attributes.remove(geometry.attributes[name]);
		}

		for (name in Reflect.fields(geometry.morphAttributes)) {
			var array = geometry.morphAttributes[name];

			for (i in 0...array.length) {
				attributes.remove(array[i]);
			}
		}

		geometry.removeEventListener('dispose', onGeometryDispose);

		geometries.remove(geometry.id);

		var attribute = wireframeAttributes.get(geometry);

		if (attribute != null) {
			attributes.remove(attribute);
			wireframeAttributes.set(geometry, null);
		}

		bindingStates.releaseStatesOfGeometry(geometry);

		if (geometry.isInstancedBufferGeometry) {
			Reflect.deleteField(geometry, '_maxInstanceCount');
		}

		info.memory.geometries--;
	}

	public function get(object:Dynamic, geometry:Dynamic) {
		if (geometries.exists(geometry.id)) return geometry;

		geometry.addEventListener('dispose', onGeometryDispose);

		geometries.set(geometry.id, true);

		info.memory.geometries++;

		return geometry;
	}

	public function update(geometry:Dynamic) {
		var geometryAttributes = geometry.attributes;

		for (name in Reflect.fields(geometryAttributes)) {
			attributes.update(geometryAttributes[name], gl.ARRAY_BUFFER);
		}

		var morphAttributes = geometry.morphAttributes;

		for (name in Reflect.fields(morphAttributes)) {
			var array = morphAttributes[name];

			for (i in 0...array.length) {
				attributes.update(array[i], gl.ARRAY_BUFFER);
			}
		}
	}

	private function updateWireframeAttribute(geometry:Dynamic) {
		var indices:Array<Int> = [];

		var geometryIndex = geometry.index;
		var geometryPosition = geometry.attributes.position;
		var version = 0;

		if (geometryIndex != null) {
			var array = geometryIndex.array;
			version = geometryIndex.version;

			for (i in 0...array.length) {
				if (i % 3 == 0) {
					var a = array[i];
					var b = array[i + 1];
					var c = array[i + 2];

					indices.push(a, b, b, c, c, a);
				}
			}
		} else if (geometryPosition != null) {
			var array = geometryPosition.array;
			version = geometryPosition.version;

			for (i in 0...((array.length / 3) - 1)) {
				if (i % 3 == 0) {
					var a = i;
					var b = i + 1;
					var c = i + 2;

					indices.push(a, b, b, c, c, a);
				}
			}
		} else {
			return;
		}

		var attribute:BufferAttribute = Utils.arrayNeedsUint32(indices) ? new Uint32BufferAttribute(indices, 1) : new Uint16BufferAttribute(indices, 1);
		attribute.version = version;

		var previousAttribute = wireframeAttributes.get(geometry);

		if (previousAttribute != null) attributes.remove(previousAttribute);

		wireframeAttributes.set(geometry, attribute);
	}

	public function getWireframeAttribute(geometry:Dynamic) {
		var currentAttribute = wireframeAttributes.get(geometry);

		if (currentAttribute != null) {
			var geometryIndex = geometry.index;

			if (geometryIndex != null) {
				if (currentAttribute.version < geometryIndex.version) {
					updateWireframeAttribute(geometry);
				}
			}
		} else {
			updateWireframeAttribute(geometry);
		}

		return wireframeAttributes.get(geometry);
	}

}