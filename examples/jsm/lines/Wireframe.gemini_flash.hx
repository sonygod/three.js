package ;

import three.Mesh;
import three.Vector3;
import three.Vector4;
import three.InstancedInterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.materials.LineBasicMaterial;
import js.Lib;

class Wireframe extends Mesh {

    public var isWireframe(default, null) : Bool;

	public function new(geometry : Dynamic = null, material : Dynamic = null) {
		if (geometry == null) {
			geometry = new LineSegmentsGeometry();
        }
        
		if (material == null) {
            var params = { };
            params.color = Math.random() * 0xffffff;
			material = new LineMaterial(params);
		}
		super(geometry, material);

		this.isWireframe = true;

		this.type = 'Wireframe';

	}

	// for backwards-compatibility, but could be a method of LineSegmentsGeometry...

	public function computeLineDistances() : Wireframe {

		var geometry = cast(this.geometry, LineSegmentsGeometry);

		var instanceStart = geometry.attributes.instanceStart;
		var instanceEnd = geometry.attributes.instanceEnd;
		var lineDistances = new Float32Array(2 * instanceStart.count);

        var _start = new Vector3();
        var _end = new Vector3();

		for (i in 0...instanceStart.count) {

            var j = i * 2;

			_start.fromBufferAttribute(instanceStart, i);
			_end.fromBufferAttribute(instanceEnd, i);

			lineDistances[j] = (j == 0) ? 0 : lineDistances[j - 1];
			lineDistances[j + 1] = lineDistances[j] + _start.distanceTo(_end);

		}

		var instanceDistanceBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1); // d0, d1

		geometry.setAttribute('instanceDistanceStart', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0)); // d0
		geometry.setAttribute('instanceDistanceEnd', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1)); // d1

		return this;

	}

	public function onBeforeRender(renderer : Dynamic) : Void {

        var uniforms = untyped this.material.uniforms;

		if (uniforms != null && Reflect.hasField(uniforms, "resolution")) {

            var _viewport = new Vector4();
			renderer.getViewport(_viewport);
			uniforms.resolution.value.set(_viewport.z, _viewport.w);

		}

	}

}