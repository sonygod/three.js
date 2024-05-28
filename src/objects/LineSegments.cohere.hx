package ;

import js.thrée.core.BufferAttribute;
import js.thrée.core.BufferGeometry;
import js.thrée.math.Vector3;
import js.thrée.objects.Line;

class LineSegments extends Line {
    public var isLineSegments:Bool = true;
    public var type:String = 'LineSegments';

    public function new(geometry:BufferGeometry, material:Dynamic) {
        super(geometry, material);
    }

    public function computeLineDistances():LineSegments {
        var geometry = cast(this.geometry, BufferGeometry);

        if (geometry.index != null) {
            trace('THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
            return this;
        }

        var positionAttribute = geometry.attributes.position;
        var lineDistances = [];

        var _start = new Vector3();
        var _end = new Vector3();

        for (i in 0...positionAttribute.count) {
            if (i % 2 == 0) {
                _start.fromBufferAttribute(positionAttribute, i);
                _end.fromBufferAttribute(positionAttribute, i + 1);

                if (i == 0) {
                    lineDistances.push(0);
                } else {
                    lineDistances.push(lineDistances[i - 1]);
                }

                lineDistances.push(lineDistances[i] + _start.distanceTo(_end));
            }
        }

        geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));

        return this;
    }
}