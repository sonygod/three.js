import three.Curve;
import three.Vector3;
import three.Vector4;
import three.curves.NURBSUtils;

class NURBSCurve extends Curve {

    public var degree:Int;
    public var knots:Array<Float>;
    public var controlPoints:Array<Vector4>;
    public var startKnot:Int;
    public var endKnot:Int;

    public function new(degree:Int, knots:Array<Float>, controlPoints:Array<Vector3>, startKnot:Int = 0, endKnot:Int = -1) {
        super();

        this.degree = degree;
        this.knots = knots;
        this.controlPoints = [];
        this.startKnot = startKnot;
        this.endKnot = endKnot == -1 ? knots.length - 1 : endKnot;

        for (point in controlPoints) {
            this.controlPoints.push(new Vector4(point.x, point.y, point.z, point.w));
        }
    }

    public function getPoint(t:Float, optionalTarget:Vector3 = null):Vector3 {
        var point = optionalTarget == null ? new Vector3() : optionalTarget;

        var u = this.knots[this.startKnot] + t * (this.knots[this.endKnot] - this.knots[this.startKnot]);

        var hpoint = NURBSUtils.calcBSplinePoint(this.degree, this.knots, this.controlPoints, u);

        if (hpoint.w != 1.0) {
            hpoint.divideScalar(hpoint.w);
        }

        return point.set(hpoint.x, hpoint.y, hpoint.z);
    }

    public function getTangent(t:Float, optionalTarget:Vector3 = null):Vector3 {
        var tangent = optionalTarget == null ? new Vector3() : optionalTarget;

        var u = this.knots[0] + t * (this.knots[this.knots.length - 1] - this.knots[0]);
        var ders = NURBSUtils.calcNURBSDerivatives(this.degree, this.knots, this.controlPoints, u, 1);
        tangent.copy(ders[1]).normalize();

        return tangent;
    }
}