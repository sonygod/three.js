import three.InstancedInterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Mesh;
import three.Vector3;
import three.Vector4;
import jsm.lines.LineSegmentsGeometry;
import jsm.lines.LineMaterial;

class Wireframe extends Mesh {

    private var _start:Vector3 = new Vector3();
    private var _end:Vector3 = new Vector3();
    private var _viewport:Vector4 = new Vector4();

    public function new(geometry:LineSegmentsGeometry = new LineSegmentsGeometry(), material:LineMaterial = new LineMaterial( { color: Math.random() * 0xffffff } )) {

        super(geometry, material);

        this.isWireframe = true;

        this.type = 'Wireframe';
    }

    public function computeLineDistances():Wireframe {

        var geometry = this.geometry;

        var instanceStart = geometry.attributes.instanceStart;
        var instanceEnd = geometry.attributes.instanceEnd;
        var lineDistances = new Array<Float>(2 * instanceStart.count);

        for (var i = 0, j = 0, l = instanceStart.count; i < l; i++, j += 2) {

            _start.fromBufferAttribute(instanceStart, i);
            _end.fromBufferAttribute(instanceEnd, i);

            lineDistances[j] = (j == 0) ? 0 : lineDistances[j - 1];
            lineDistances[j + 1] = lineDistances[j] + _start.distanceTo(_end);
        }

        var instanceDistanceBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1);

        geometry.setAttribute('instanceDistanceStart', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0));
        geometry.setAttribute('instanceDistanceEnd', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1));

        return this;
    }

    public function onBeforeRender(renderer:Renderer) {

        var uniforms = this.material.uniforms;

        if (uniforms != null && uniforms.hasKey('resolution')) {

            renderer.getViewport(_viewport);
            this.material.uniforms.get('resolution').value.set(_viewport.z, _viewport.w);
        }
    }
}