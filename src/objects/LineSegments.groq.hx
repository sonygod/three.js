package three objetos;

import three.core.BufferAttribute.Float32BufferAttribute;
import three.math.Vector3;

class LineSegments extends Line {
    public var isLineSegments:Bool = true;
    public var type:String = 'LineSegments';

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);
    }

    public function computeLineDistances():LineSegments {
        var geometry:Geometry = this.geometry;

        if (geometry.index == null) {
            var positionAttribute:BufferAttribute = geometry.attributes.position;
            var lineDistances:Array<Float> = [];

            for (i in 0...positionAttribute.count) {
                _start.fromBufferAttribute(positionAttribute, i);
                _end.fromBufferAttribute(positionAttribute, i + 1);

                lineDistances[i] = (i == 0) ? 0 : lineDistances[i - 1];
                lineDistances[i + 1] = lineDistances[i] + _start.distanceTo(_end);
            }

            geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
        } else {
            trace('THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
        }

        return this;
    }
}

private static var _start:Vector3 = new Vector3();
private static var _end:Vector3 = new Vector3();