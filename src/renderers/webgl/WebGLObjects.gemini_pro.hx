class WebGLObjects {

	public var updateMap:WeakMap<Dynamic, Int>;

	public function new(gl:Dynamic, geometries:Dynamic, attributes:Dynamic, info:Dynamic) {
		this.updateMap = new WeakMap();
	}

	public function update(object:Dynamic):Dynamic {

		var frame = info.render.frame;

		var geometry = object.geometry;
		var buffergeometry = geometries.get(object, geometry);

		// Update once per frame

		if (this.updateMap.get(buffergeometry) != frame) {

			geometries.update(buffergeometry);

			this.updateMap.set(buffergeometry, frame);

		}

		if (Std.is(object, InstancedMesh)) {

			if (object.hasEventListener('dispose', onInstancedMeshDispose) == false) {

				object.addEventListener('dispose', onInstancedMeshDispose);

			}

			if (this.updateMap.get(object) != frame) {

				attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);

				if (object.instanceColor != null) {

					attributes.update(object.instanceColor, gl.ARRAY_BUFFER);

				}

				this.updateMap.set(object, frame);

			}

		}

		if (Std.is(object, SkinnedMesh)) {

			var skeleton = object.skeleton;

			if (this.updateMap.get(skeleton) != frame) {

				skeleton.update();

				this.updateMap.set(skeleton, frame);

			}

		}

		return buffergeometry;

	}

	public function dispose() {

		this.updateMap = new WeakMap();

	}

	public function onInstancedMeshDispose(event:Dynamic) {

		var instancedMesh = event.target;

		instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);

		attributes.remove(instancedMesh.instanceMatrix);

		if (instancedMesh.instanceColor != null) attributes.remove(instancedMesh.instanceColor);

	}

}

class InstancedMesh {
	public var instanceMatrix:Dynamic;
	public var instanceColor:Dynamic;
}

class SkinnedMesh {
	public var skeleton:Dynamic;
}