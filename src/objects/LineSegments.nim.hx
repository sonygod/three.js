import Line.Line;
import Vector3.Vector3;
import Float32BufferAttribute.Float32BufferAttribute;

class LineSegments extends Line {

    public var isLineSegments:Bool = true;
    public var type:String = 'LineSegments';

    public function new(geometry:Dynamic, material:Dynamic) {
        super(geometry, material);
    }

    public function computeLineDistances():LineSegments {
        var geometry:Dynamic = this.geometry;

        // we assume non-indexed geometry
        if (geometry.index == null) {
            var positionAttribute:Dynamic = geometry.attributes.position;
            var lineDistances:Array<Float> = [];

            for (i in 0...positionAttribute.count) {
                if (i % 2 == 0) {
                    _start.fromBufferAttribute(positionAttribute, i);
                    _end.fromBufferAttribute(positionAttribute, i + 1);

                    lineDistances[i] = (i == 0) ? 0 : lineDistances[i - 1];
                    lineDistances[i + 1] = lineDistances[i] + _start.distanceTo(_end);
                }
            }

            geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
        } else {
            trace.warn('LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
        }

        return this;
    }

    private static var _start:Vector3 = Vector3.make();
    private static var _end:Vector3 = Vector3.make();
}