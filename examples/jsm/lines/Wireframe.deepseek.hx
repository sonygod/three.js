import three.InstancedInterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Mesh;
import three.Vector3;
import three.Vector4;
import three.examples.jsm.lines.LineSegmentsGeometry;
import three.examples.jsm.lines.LineMaterial;

class Wireframe extends Mesh {

    static var _start:Vector3 = new Vector3();
    static var _end:Vector3 = new Vector3();
    static var _viewport:Vector4 = new Vector4();

    public function new(geometry:LineSegmentsGeometry = new LineSegmentsGeometry(), material:LineMaterial = new LineMaterial({color: Math.random() * 0xffffff})):Void {
        super(geometry, material);
        this.isWireframe = true;
        this.type = 'Wireframe';
    }

    public function computeLineDistances():Wireframe {
        var geometry = this.geometry;
        var instanceStart = geometry.attributes.instanceStart;
        var instanceEnd = geometry.attributes.instanceEnd;
        var lineDistances = new Float32Array(2 * instanceStart.count);

        for (i in 0...instanceStart.count) {
            _start.fromBufferAttribute(instanceStart, i);
            _end.fromBufferAttribute(instanceEnd, i);
            lineDistances[2 * i] = (i == 0) ? 0 : lineDistances[2 * (i - 1) + 1];
            lineDistances[2 * i + 1] = lineDistances[2 * i] + _start.distanceTo(_end);
        }

        var instanceDistanceBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1); // d0, d1
        geometry.setAttribute('instanceDistanceStart', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0)); // d0
        geometry.setAttribute('instanceDistanceEnd', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1)); // d1

        return this;
    }

    public function onBeforeRender(renderer:Renderer):Void {
        var uniforms = this.material.uniforms;

        if (uniforms != null && uniforms.resolution != null) {
            renderer.getViewport(_viewport);
            this.material.uniforms.resolution.value.set(_viewport.z, _viewport.w);
        }
    }
}