import threejs.extras.core.Path;
import threejs.geometries.LatheGeometry;

class CapsuleGeometry extends LatheGeometry {

    public var radius:Float;
    public var length:Float;
    public var capSegments:Int;
    public var radialSegments:Int;

    public function new(radius:Float = 1, length:Float = 1, capSegments:Int = 4, radialSegments:Int = 8) {
        var path = new Path();
        path.absarc(0, -length / 2, radius, Math.PI * 1.5, 0);
        path.absarc(0, length / 2, radius, 0, Math.PI * 0.5);

        super(path.getPoints(capSegments), radialSegments);

        this.radius = radius;
        this.length = length;
        this.capSegments = capSegments;
        this.radialSegments = radialSegments;

        this.type = 'CapsuleGeometry';
    }

    public static function fromJSON(data:Dynamic):CapsuleGeometry {
        return new CapsuleGeometry(data.radius, data.length, data.capSegments, data.radialSegments);
    }
}