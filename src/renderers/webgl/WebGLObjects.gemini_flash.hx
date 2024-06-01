class WebGLObjects {

	public var updateMap:WeakMap<Dynamic, Int>;
	public var geometries:Dynamic;
	public var attributes:Dynamic;
	public var info:Dynamic;

	public function new(gl:Dynamic, geometries:Dynamic, attributes:Dynamic, info:Dynamic) {
		this.updateMap = new WeakMap();
		this.geometries = geometries;
		this.attributes = attributes;
		this.info = info;
	}

	public function update(object:Dynamic):Dynamic {

		var frame = this.info.render.frame;

		var geometry = object.geometry;
		var buffergeometry = this.geometries.get(object, geometry);

		// Update once per frame

		if (this.updateMap.get(buffergeometry) != frame) {

			this.geometries.update(buffergeometry);

			this.updateMap.set(buffergeometry, frame);

		}

		if (Std.is(object, InstancedMesh)) {

			if (!object.hasEventListener("dispose", onInstancedMeshDispose)) {

				object.addEventListener("dispose", onInstancedMeshDispose);

			}

			if (this.updateMap.get(object) != frame) {

				this.attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);

				if (object.instanceColor != null) {

					this.attributes.update(object.instanceColor, gl.ARRAY_BUFFER);

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

		instancedMesh.removeEventListener("dispose", onInstancedMeshDispose);

		this.attributes.remove(instancedMesh.instanceMatrix);

		if (instancedMesh.instanceColor != null) this.attributes.remove(instancedMesh.instanceColor);

	}

}

class InstancedMesh {

	public var instanceMatrix:Dynamic;
	public var instanceColor:Dynamic;

	public function new() {

	}

	public function hasEventListener(type:String, listener:Dynamic):Bool {
		// This is a placeholder. You need to implement event handling in your Haxe code.
		return false;
	}

	public function addEventListener(type:String, listener:Dynamic):Void {
		// This is a placeholder. You need to implement event handling in your Haxe code.
	}

	public function removeEventListener(type:String, listener:Dynamic):Void {
		// This is a placeholder. You need to implement event handling in your Haxe code.
	}

}

class SkinnedMesh {

	public var skeleton:Dynamic;

	public function new() {

	}

}