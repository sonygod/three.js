package geometry;

import js.Path;
import js.LatheGeometry;

class CapsuleGeometry extends LatheGeometry {
    public var radius:Float = 1;
    public var length:Float = 1;
    public var capSegments:Int = 4;
    public var radialSegments:Int = 8;

    public function new(?radius:Float, ?length:Float, ?capSegments:Int, ?radialSegments:Int) {
        if (radius == null) radius = 1;
        if (length == null) length = 1;
        if (capSegments == null) capSegments = 4;
        if (radialSegments == null) radialSegments = 8;

        var path = new Path();
        path.absarc(0, -length / 2, radius, Math.PI * 1.5, 0);
        path.absarc(0, length / 2, radius, 0, Math.PI * 0.5);

        super([path.getPoints(capSegments)], radialSegments);

        this.type = 'CapsuleGeometry';

        this.parameters = {
            'radius' => radius,
            'length' => length,
            'capSegments' => capSegments,
            'radialSegments' => radialSegments
        };
    }

    public static function fromJSON(data:Dynamic) {
        return new CapsuleGeometry(
            data.radius,
            data.length,
            data.capSegments,
            data.radialSegments
        );
    }
}