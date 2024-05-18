package three.js.examples.jsm.lines;

import three.InstancedInterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Mesh;
import three.Vector3;
import three.Vector4;
import lines.LineSegmentsGeometry;
import lines.LineMaterial;

class Wireframe extends Mesh {
    private var _start:Vector3 = new Vector3();
    private var _end:Vector3 = new Vector3();
    private var _viewport:Vector4 = new Vector4();

    public function new(geometry:LineSegmentsGeometry = new LineSegmentsGeometry(), material:LineMaterial = new LineMaterial({ color: Math.random() * 0xffffff })) {
        super(geometry, material);

        isWireframe = true;
        type = 'Wireframe';
    }

    // for backwards-compatibility, but could be a method of LineSegmentsGeometry...
    public function computeLineDistances():Wireframe {
        var geometry:LineSegmentsGeometry = cast geometry;
        var instanceStart:InstancedInterleavedBuffer = geometry.attributes.instanceStart;
        var instanceEnd:InstancedInterleavedBuffer = geometry.attributes.instanceEnd;
        var lineDistances:Float32Array = new Float32Array(2 * instanceStart.count);

        for (i in 0...instanceStart.count) {
            _start.fromBufferAttribute(instanceStart, i);
            _end.fromBufferAttribute(instanceEnd, i);

            lineDistances[i * 2] = (i == 0) ? 0 : lineDistances[i * 2 - 1];
            lineDistances[i * 2 + 1] = lineDistances[i * 2] + _start.distanceTo(_end);
        }

        var instanceDistanceBuffer:InstancedInterleavedBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1); // d0, d1
        geometry.setAttribute('instanceDistanceStart', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0)); // d0
        geometry.setAttribute('instanceDistanceEnd', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1)); // d1

        return this;
    }

    public function onBeforeRender(renderer:Renderer):Void {
        var uniforms:Dynamic = material.uniforms;

        if (uniforms != null && uniforms.resolution != null) {
            renderer.getViewport(_viewport);
            material.uniforms.resolution.value.set(_viewport.z, _viewport.w);
        }
    }
}