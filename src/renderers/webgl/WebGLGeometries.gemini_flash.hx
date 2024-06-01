import haxe.ds.WeakMap;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.InstancedBufferGeometry;
import three.core.Uint16BufferAttribute;
import three.core.Uint32BufferAttribute;
import three.utils.Utils;

class WebGLGeometries {

	private var geometries:Map<Int,Bool> = new Map();
	private var wireframeAttributes:WeakMap<BufferGeometry,BufferAttribute> = new WeakMap();

	public function new(gl:Dynamic, attributes:Dynamic, info:Dynamic, bindingStates:Dynamic) {
		this.onGeometryDispose = this.onGeometryDispose.bind(this);
	}

	private function onGeometryDispose(event:Dynamic) {
		var geometry = event.target;

		if (geometry.index != null) {
			attributes.remove(geometry.index);
		}

		for (name in geometry.attributes) {
			attributes.remove(geometry.attributes[name]);
		}

		for (name in geometry.morphAttributes) {
			var array = geometry.morphAttributes[name];
			for (i in 0...array.length) {
				attributes.remove(array[i]);
			}
		}

		geometry.removeEventListener('dispose', this.onGeometryDispose);
		geometries.remove(geometry.id);

		var attribute = wireframeAttributes.get(geometry);
		if (attribute != null) {
			attributes.remove(attribute);
			wireframeAttributes.remove(geometry);
		}

		bindingStates.releaseStatesOfGeometry(geometry);

		if (Std.is(geometry, InstancedBufferGeometry)) {
			geometry._maxInstanceCount = null;
		}

		info.memory.geometries--;
	}

	public function get(object:Dynamic, geometry:BufferGeometry):BufferGeometry {
		if (geometries.exists(geometry.id)) return geometry;

		geometry.addEventListener('dispose', this.onGeometryDispose);
		geometries.set(geometry.id, true);
		info.memory.geometries++;

		return geometry;
	}

	public function update(geometry:BufferGeometry) {
		var geometryAttributes = geometry.attributes;

		// Updating index buffer in VAO now. See WebGLBindingStates.

		for (name in geometryAttributes) {
			attributes.update(geometryAttributes[name], gl.ARRAY_BUFFER);
		}

		// morph targets

		var morphAttributes = geometry.morphAttributes;
		for (name in morphAttributes) {
			var array = morphAttributes[name];
			for (i in 0...array.length) {
				attributes.update(array[i], gl.ARRAY_BUFFER);
			}
		}
	}

	public function updateWireframeAttribute(geometry:BufferGeometry) {
		var indices:Array<Int> = new Array();
		var geometryIndex = geometry.index;
		var geometryPosition = geometry.attributes.position;
		var version = 0;

		if (geometryIndex != null) {
			var array = geometryIndex.array;
			version = geometryIndex.version;
			for (i in 0...array.length) {
				if (i % 3 == 0) {
					indices.push(array[i]);
					indices.push(array[i + 1]);
				} else if (i % 3 == 1) {
					indices.push(array[i]);
					indices.push(array[i + 1]);
				} else if (i % 3 == 2) {
					indices.push(array[i]);
					indices.push(array[i - 2]);
				}
			}
		} else if (geometryPosition != null) {
			var array = geometryPosition.array;
			version = geometryPosition.version;
			for (i in 0...((array.length / 3) - 1)) {
				if (i % 3 == 0) {
					indices.push(i);
					indices.push(i + 1);
				} else if (i % 3 == 1) {
					indices.push(i);
					indices.push(i + 1);
				} else if (i % 3 == 2) {
					indices.push(i);
					indices.push(i - 2);
				}
			}
		} else {
			return;
		}

		var attribute = new (if (Utils.arrayNeedsUint32(indices)) Uint32BufferAttribute else Uint16BufferAttribute)(indices, 1);
		attribute.version = version;

		// Updating index buffer in VAO now. See WebGLBindingStates

		//

		var previousAttribute = wireframeAttributes.get(geometry);
		if (previousAttribute != null) attributes.remove(previousAttribute);

		//

		wireframeAttributes.set(geometry, attribute);
	}

	public function getWireframeAttribute(geometry:BufferGeometry):BufferAttribute {
		var currentAttribute = wireframeAttributes.get(geometry);
		if (currentAttribute != null) {
			var geometryIndex = geometry.index;
			if (geometryIndex != null) {
				// if the attribute is obsolete, create a new one
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