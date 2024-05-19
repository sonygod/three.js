import three.js.src.objects.Line;
import three.js.src.math.Vector3;
import three.js.src.core.BufferAttribute;

class LineSegments extends Line {

    static var _start:Vector3 = new Vector3();
    static var _end:Vector3 = new Vector3();

    public function new(geometry, material) {
        super(geometry, material);

        this.isLineSegments = true;
        this.type = 'LineSegments';
    }

    public function computeLineDistances():LineSegments {
        var geometry = this.geometry;

        if (geometry.index == null) {
            var positionAttribute = geometry.attributes.position;
            var lineDistances = [];

            for (i in 0...positionAttribute.count) {
                _start.fromBufferAttribute(positionAttribute, i);
                _end.fromBufferAttribute(positionAttribute, i + 1);

                lineDistances[i] = (i == 0) ? 0 : lineDistances[i - 1];
                lineDistances[i + 1] = lineDistances[i] + _start.distanceTo(_end);
            }

            geometry.setAttribute('lineDistance', new BufferAttribute(lineDistances, 1));
        } else {
            trace('THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
        }

        return this;
    }
}