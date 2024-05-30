package three.js.examples.jsm.curves;

import three.Curve;
import three.Vector3;
import three.Vector4;

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

        for (i in 0...controlPoints.length) {
            var point = controlPoints[i];
            this.controlPoints.push(new Vector4(point.x, point.y, point.z, point.w == null ? 1.0 : point.w));
        }
    }

    override public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        var u:Float = knots[startKnot] + t * (knots[endKnot] - knots[startKnot]);
        var hpoint:Vector4 = NURBSUtils.calcBSplinePoint(degree, knots, controlPoints, u);
        if (hpoint.w != 1.0) {
            hpoint.divideScalar(hpoint.w);
        }
        return point.set(hpoint.x, hpoint.y, hpoint.z);
    }

    override public function getTangent(t:Float, ?optionalTarget:Vector3):Vector3 {
        var tangent:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        var u:Float = knots[0] + t * (knots[knots.length - 1] - knots[0]);
        var ders:Array<Vector4> = NURBSUtils.calcNURBSDerivatives(degree, knots, controlPoints, u, 1);
        tangent.copy(ders[1]).normalize();
        return tangent;
    }
}

// export NURBSCurve class