package three.js.src.renderers.webgl;

import js.html.webgl.RenderingContext;
import js.html.webgl.Buffer;
import js.html.webgl.ArrayBuffer;
import haxe.ds.WeakMap;

class WebGLObjects {
	
	var gl:RenderingContext;
	var geometries:Geometries;
	var attributes:Attributes;
	var info:RenderInfo;
	var updateMap:WeakMap<Dynamic, Int>;

	public function new(gl:RenderingContext, geometries:Geometries, attributes:Attributes, info:RenderInfo) {
		this.gl = gl;
		this.geometries = geometries;
		this.attributes = attributes;
		this.info = info;
		updateMap = new WeakMap();
	}

	function update(object:Dynamic):Buffer {
		var frame:Int = info.render.frame;
		var geometry:Geometry = object.geometry;
		var bufferGeometry:BufferGeometry = geometries.get(object, geometry);

		// Update once per frame
		if (updateMap.get(bufferGeometry) != frame) {
			geometries.update(bufferGeometry);
			updateMap.set(bufferGeometry, frame);
		}

		if (object.isInstancedMesh) {
			if (!object.hasEventListener('dispose', onInstancedMeshDispose)) {
				object.addEventListener('dispose', onInstancedMeshDispose);
			}
			if (updateMap.get(object) != frame) {
				attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);
				if (object.instanceColor != null) {
					attributes.update(object.instanceColor, gl.ARRAY_BUFFER);
				}
				updateMap.set(object, frame);
			}
		}

		if (object.isSkinnedMesh) {
			var skeleton:Skeleton = object.skeleton;
			if (updateMap.get(skeleton) != frame) {
				skeleton.update();
				updateMap.set(skeleton, frame);
			}
		}

		return bufferGeometry;
	}

	function dispose():Void {
		updateMap = new WeakMap();
	}

	function onInstancedMeshDispose(event:Event):Void {
		var instancedMesh:InstancedMesh = cast event.target;
		instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);
		attributes.remove(instancedMesh.instanceMatrix);
		if (instancedMesh.instanceColor != null) attributes.remove(instancedMesh.instanceColor);
	}

	public function expose():{ update:Dynamic->Buffer, dispose: Void->Void } {
		return { update: update, dispose: dispose };
	}
}