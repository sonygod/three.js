import three.core.BufferAttribute;
import three.utils.arrayNeedsUint32;

class WebGLGeometries {

	var geometries:Map<Int, Bool>;
	var wireframeAttributes:WeakMap<Geometry, BufferAttribute>;

	public function new(gl:Dynamic, attributes:Dynamic, info:Dynamic, bindingStates:Dynamic) {
		geometries = new Map();
		wireframeAttributes = new WeakMap();
	}

	private function onGeometryDispose(event:Dynamic):Void {
		var geometry = event.target;
		if (geometry.index !== null) {
			attributes.remove(geometry.index);
		}
		for (name in geometry.attributes) {
			attributes.remove(geometry.attributes[name]);
		}
		for (name in geometry.morphAttributes) {
			var array = geometry.morphAttributes[name];
			for (i in array.length) {
				attributes.remove(array[i]);
			}
		}
		geometry.removeEventListener('dispose', onGeometryDispose);
		geometries.delete(geometry.id);
		var attribute = wireframeAttributes.get(geometry);
		if (attribute) {
			attributes.remove(attribute);
			wireframeAttributes.delete(geometry);
		}
		bindingStates.releaseStatesOfGeometry(geometry);
		if (geometry.isInstancedBufferGeometry === true) {
			delete geometry._maxInstanceCount;
		}
		info.memory.geometries--;
	}

	public function get(object:Dynamic, geometry:Geometry):Geometry {
		if (geometries.exists(geometry.id)) return geometry;
		geometry.addEventListener('dispose', onGeometryDispose);
		geometries[geometry.id] = true;
		info.memory.geometries++;
		return geometry;
	}

	public function update(geometry:Geometry):Void {
		var geometryAttributes = geometry.attributes;
		for (name in geometryAttributes) {
			attributes.update(geometryAttributes[name], gl.ARRAY_BUFFER);
		}
		var morphAttributes = geometry.morphAttributes;
		for (name in morphAttributes) {
			var array = morphAttributes[name];
			for (i in array.length) {
				attributes.update(array[i], gl.ARRAY_BUFFER);
			}
		}
	}

	public function updateWireframeAttribute(geometry:Geometry):Void {
		var indices = [];
		var geometryIndex = geometry.index;
		var geometryPosition = geometry.attributes.position;
		var version = 0;
		if (geometryIndex !== null) {
			var array = geometryIndex.array;
			version = geometryIndex.version;
			for (i in array.length) {
				var a = array[i + 0];
				var b = array[i + 1];
				var c = array[i + 2];
				indices.push(a, b, b, c, c, a);
			}
		} else if (geometryPosition !== undefined) {
			var array = geometryPosition.array;
			version = geometryPosition.version;
			for (i in (array.length / 3) - 1) {
				var a = i + 0;
				var b = i + 1;
				var c = i + 2;
				indices.push(a, b, b, c, c, a);
			}
		} else {
			return;
		}
		var attribute = new (arrayNeedsUint32(indices) ? Uint32BufferAttribute : Uint16BufferAttribute)(indices, 1);
		attribute.version = version;
		var previousAttribute = wireframeAttributes.get(geometry);
		if (previousAttribute) attributes.remove(previousAttribute);
		wireframeAttributes.set(geometry, attribute);
	}

	public function getWireframeAttribute(geometry:Geometry):BufferAttribute {
		var currentAttribute = wireframeAttributes.get(geometry);
		if (currentAttribute) {
			var geometryIndex = geometry.index;
			if (geometryIndex !== null) {
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