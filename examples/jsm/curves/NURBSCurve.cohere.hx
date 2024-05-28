import js.three.Curve;
import js.three.Vector3;
import js.three.Vector4;

class NURBSUtils {
    public static function calcBSplinePoint(degree: Int, knots: Array<Float>, controlPoints: Array<Vector4>, u: Float): Vector4 {
        // Implementation of calcBSplinePoint
        // ...
    }

    public static function calcNURBSDerivatives(degree: Int, knots: Array<Float>, controlPoints: Array<Vector4>, u: Float, numDerivatives: Int): Array<Vector4> {
        // Implementation of calcNURBSDerivatives
        // ...
    }
}

class NURBSCurve extends Curve {
    public var degree: Int;
    public var knots: Array<Float>;
    public var controlPoints: Array<Vector4>;
    public var startKnot: Int;
    public var endKnot: Int;

    public function new(degree: Int, knots: Array<Float>, controlPoints: Array<Vector4>, startKnot: Int = 0, endKnot: Int = knots.length - 1) {
        super();
        this.degree = degree;
        this.knots = knots;
        this.controlPoints = [];
        this.startKnot = startKnot;
        this.endKnot = endKnot;

        for (i in 0...controlPoints.length) {
            let point = controlPoints[i];
            this.controlPoints.push(new Vector4(point.x, point.y, point.z, point.w));
        }
    }

    public function getPoint(t: Float, optionalTarget: Vector3 = new Vector3()): Vector3 {
        let point = optionalTarget;
        let u = this.knots[this.startKnot] + t * (this.knots[this.endKnot] - this.knots[this.startKnot]); // linear mapping t->u
        let hpoint = NURBSUtils.calcBSplinePoint(this.degree, this.knots, this.controlPoints, u);

        if (hpoint.w != 1.0) {
            // project to 3D space: (wx, wy, wz, w) -> (x, y, z, 1)
            hpoint /= hpoint.w;
        }

        return point.set(hpoint.x, hpoint.y, hpoint.z);
    }

    public function getTangent(t: Float, optionalTarget: Vector3 = new Vector3()): Vector3 {
        let tangent = optionalTarget;
        let u = this.knots[0] + t * (this.knots[this.knots.length - 1] - this.knots[0]);
        let ders = NURBSUtils.calcNURBSDerivatives(this.degree, this.knots, this.controlPoints, u, 1);
        tangent.copy(ders[1]).normalize();

        return tangent;
    }
}

class Export {
    public static var NURBSCurve: NURBSCurve;
}