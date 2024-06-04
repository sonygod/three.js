import three.extras.curves.Curve;
import three.math.Vector3;
import three.math.Vector4;
import three.extras.curves.NURBSUtils;

/**
 * NURBS curve object
 *
 * Derives from Curve, overriding getPoint and getTangent.
 *
 * Implementation is based on (x, y [, z=0 [, w=1]]) control points with w=weight.
 *
 **/
class NURBSCurve extends Curve {

	public var degree:Int;
	public var knots:Array<Float>;
	public var controlPoints:Array<Vector4>;
	public var startKnot:Int;
	public var endKnot:Int;

	public function new(degree:Int, knots:Array<Float>, controlPoints:Array<Dynamic>, startKnot:Int = 0, endKnot:Int = 0) {
		super();
		this.degree = degree;
		this.knots = knots;
		this.controlPoints = [];
		this.startKnot = startKnot;
		this.endKnot = endKnot == 0 ? knots.length - 1 : endKnot;

		for (i in 0...controlPoints.length) {
			// ensure Vector4 for control points
			var point = controlPoints[i];
			this.controlPoints[i] = new Vector4(cast point.x, cast point.y, cast point.z, cast point.w);
		}
	}

	public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
		var point = optionalTarget;

		var u = this.knots[this.startKnot] + t * (this.knots[this.endKnot] - this.knots[this.startKnot]); // linear mapping t->u

		// following results in (wx, wy, wz, w) homogeneous point
		var hpoint = NURBSUtils.calcBSplinePoint(this.degree, this.knots, this.controlPoints, u);

		if (hpoint.w != 1.0) {

			// project to 3D space: (wx, wy, wz, w) -> (x, y, z, 1)
			hpoint.divideScalar(hpoint.w);

		}

		return point.set(hpoint.x, hpoint.y, hpoint.z);
	}

	public function getTangent(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
		var tangent = optionalTarget;

		var u = this.knots[0] + t * (this.knots[this.knots.length - 1] - this.knots[0]);
		var ders = NURBSUtils.calcNURBSDerivatives(this.degree, this.knots, this.controlPoints, u, 1);
		tangent.copy(ders[1]).normalize();

		return tangent;
	}
}