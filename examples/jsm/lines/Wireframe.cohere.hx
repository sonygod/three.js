import js.three.InstancedInterleavedBuffer;
import js.three.InterleavedBufferAttribute;
import js.three.Mesh;
import js.three.Vector3;
import js.three.Vector4;

import js.three.lines.LineMaterial;
import js.three.lines.LineSegmentsGeometry;

class Wireframe extends Mesh {
    public var isWireframe:Bool = true;
    public var type:String = 'Wireframe';

    public function new(?geometry:LineSegmentsGeometry, ?material:LineMaterial) {
        super(geometry ?? new LineSegmentsGeometry(), material ?? new LineMaterial({ color: Std.random() * 0xffffff }));
    }

    public function computeLineDistances():Void {
        var geometry = cast(this.geometry, LineSegmentsGeometry);
        var instanceStart = geometry.attributes.instanceStart;
        var instanceEnd = geometry.attributes.instanceEnd;
        var lineDistances = new Float32Array(2 * instanceStart.count);

        var i:Int, j:Int, l:Int;
        var _start:Vector3 = new Vector3();
        var _end:Vector3 = new Vector3();

        for (i = 0, j = 0, l = instanceStart.count; i < l; i++, j += 2) {
            _start.fromBufferAttribute(instanceStart, i);
            _end.fromBufferAttribute(instanceEnd, i);

            lineDistances[j] = if (j == 0) 0 else lineDistances[j - 1];
            lineDistances[j + 1] = lineDistances[j] + _start.distanceTo(_end);
        }

        var instanceDistanceBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1); // d0, d1

        geometry.setAttribute('instanceDistanceStart', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0)); // d0
        geometry.setAttribute('instanceDistanceEnd', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1)); // d1
    }

    public function onBeforeRender(renderer:Dynamic):Void {
        var uniforms = this.material.uniforms;

        if (uniforms != null && uniforms.resolution != null) {
            var _viewport:Vector4 = new Vector4();
            renderer.getViewport(_viewport);
            this.material.uniforms.resolution.value.set(_viewport.z, _viewport.w);
        }
    }
}

class WireframeExport {
    public static function getWireframe():Wireframe {
        return Wireframe;
    }
}