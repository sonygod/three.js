import three.Curve;
import three.Vector3;
import three.geometries.ParametricGeometry;

class ParametricGeometries {
    public static function klein(v: Float, u: Float, target: Vector3): Void {
        u *= Math.PI;
        v *= 2 * Math.PI;

        u = u * 2;
        var x: Float;
        var z: Float;
        if (u < Math.PI) {
            x = 3 * Math.cos(u) * (1 + Math.sin(u)) + (2 * (1 - Math.cos(u) / 2)) * Math.cos(u) * Math.cos(v);
            z = -8 * Math.sin(u) - 2 * (1 - Math.cos(u) / 2) * Math.sin(u) * Math.cos(v);
        } else {
            x = 3 * Math.cos(u) * (1 + Math.sin(u)) + (2 * (1 - Math.cos(u) / 2)) * Math.cos(v + Math.PI);
            z = -8 * Math.sin(u);
        }

        var y = -2 * (1 - Math.cos(u) / 2) * Math.sin(v);

        target.set(x, y, z);
    }

    public static function plane(width: Float, height: Float): Function {
        return function(u: Float, v: Float, target: Vector3): Void {
            var x = u * width;
            var y = 0;
            var z = v * height;

            target.set(x, y, z);
        };
    }

    public static function mobius(u: Float, t: Float, target: Vector3): Void {
        u = u - 0.5;
        var v = 2 * Math.PI * t;

        var a = 2;

        var x = Math.cos(v) * (a + u * Math.cos(v / 2));
        var y = Math.sin(v) * (a + u * Math.cos(v / 2));
        var z = u * Math.sin(v / 2);

        target.set(x, y, z);
    }

    public static function mobius3d(u: Float, t: Float, target: Vector3): Void {
        u *= Math.PI;
        t *= 2 * Math.PI;

        u = u * 2;
        var phi = u / 2;
        var major = 2.25;
        var a = 0.125;
        var b = 0.65;

        var x = a * Math.cos(t) * Math.cos(phi) - b * Math.sin(t) * Math.sin(phi);
        var z = a * Math.cos(t) * Math.sin(phi) + b * Math.sin(t) * Math.cos(phi);
        var y = (major + x) * Math.sin(u);
        x = (major + x) * Math.cos(u);

        target.set(x, y, z);
    }
}

class TubeGeometry extends ParametricGeometry {
    public function new(path: Curve, segments: Int = 64, radius: Float = 1, segmentsRadius: Int = 8, closed: Bool = false) {
        super(null, segments, segmentsRadius);
        // rest of the code...
    }
}

class TorusKnotGeometry extends TubeGeometry {
    public function new(radius: Float = 200, tube: Float = 40, segmentsT: Int = 64, segmentsR: Int = 8, p: Int = 2, q: Int = 3) {
        // rest of the code...
    }
}

class SphereGeometry extends ParametricGeometry {
    public function new(size: Float, u: Int, v: Int) {
        // rest of the code...
    }
}

class PlaneGeometry extends ParametricGeometry {
    public function new(width: Float, depth: Float, segmentsWidth: Int, segmentsDepth: Int) {
        // rest of the code...
    }
}