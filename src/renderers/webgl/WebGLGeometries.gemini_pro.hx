import haxe.ds.WeakMap;
import haxe.ds.StringMap;
import haxe.ui.backend.webgl.BufferAttribute;
import haxe.ui.backend.webgl.WebGLBufferAttribute;
import haxe.ui.backend.webgl.WebGLContext;
import haxe.ui.backend.webgl.WebGLGeometry;
import haxe.ui.backend.webgl.WebGLMemoryInfo;
import haxe.ui.backend.webgl.WebGLBindingStates;

class WebGLGeometries {

	public var geometries:Map<Int, Bool> = new Map();
	public var wireframeAttributes:WeakMap<WebGLGeometry, WebGLBufferAttribute> = new WeakMap();

	public function new(gl:WebGLContext, attributes:StringMap<WebGLBufferAttribute>, info:WebGLMemoryInfo, bindingStates:WebGLBindingStates) {
		this.onGeometryDispose = this.onGeometryDispose.bind(this);
	}

	private function onGeometryDispose(event:Dynamic) {
		var geometry = cast(event.target, WebGLGeometry);
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
		if (geometry.isInstancedBufferGeometry) {
			geometry._maxInstanceCount = null;
		}
		info.memory.geometries--;
	}

	public function get(object:Dynamic, geometry:WebGLGeometry):WebGLGeometry {
		if (geometries.exists(geometry.id)) {
			return geometry;
		}
		geometry.addEventListener('dispose', this.onGeometryDispose);
		geometries.set(geometry.id, true);
		info.memory.geometries++;
		return geometry;
	}

	public function update(geometry:WebGLGeometry) {
		var geometryAttributes = geometry.attributes;
		for (name in geometryAttributes) {
			attributes.update(geometryAttributes[name], gl.ARRAY_BUFFER);
		}
		var morphAttributes = geometry.morphAttributes;
		for (name in morphAttributes) {
			var array = morphAttributes[name];
			for (i in 0...array.length) {
				attributes.update(array[i], gl.ARRAY_BUFFER);
			}
		}
	}

	public function updateWireframeAttribute(geometry:WebGLGeometry) {
		var indices:Array<Int> = [];
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
			for (i in 0...(array.length / 3 - 1)) {
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
		var attribute:WebGLBufferAttribute;
		if (indices.length > 65535) {
			attribute = new WebGLBufferAttribute(indices, 1);
		} else {
			attribute = new BufferAttribute(indices, 1);
		}
		attribute.version = version;
		var previousAttribute = wireframeAttributes.get(geometry);
		if (previousAttribute != null) {
			attributes.remove(previousAttribute);
		}
		wireframeAttributes.set(geometry, attribute);
	}

	public function getWireframeAttribute(geometry:WebGLGeometry):WebGLBufferAttribute {
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