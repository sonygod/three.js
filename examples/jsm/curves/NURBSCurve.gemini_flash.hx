import three.Curve;
import three.Vector3;
import three.Vector4;
import NURBSUtils from './NURBSUtils';

/**
 * NURBS curve object
 *
 * Derives from Curve, overriding getPoint and getTangent.
 *
 * Implementation is based on (x, y [, z=0 [, w=1]]) control points with w=weight.
 *
 **/

class NURBSCurve extends Curve {

	public var degree(default, null):Int;
	public var knots(default, null):Array<Float>;
	public var controlPoints(default, null):Array<Vector4>;
	public var startKnot(default, null):Int;
	public var endKnot(default, null):Int;

	public function new(
		degree:Int,
		knots:Array<Float>, /* array of reals */
		controlPoints:Array<Vector3>, /* array of Vector(2|3|4) */
		startKnot:Int = 0, /* index in knots */
		endKnot:Int = 0 /* index in knots */
	) {

		super();

		this.degree = degree;
		this.knots = knots;
		this.controlPoints = [];
		// Used by periodic NURBS to remove hidden spans
		this.startKnot = startKnot;
		this.endKnot = (endKnot != 0) ? endKnot : this.knots.length - 1;

		for (i in 0...controlPoints.length) {

			// ensure Vector4 for control points
			var point = controlPoints[i];
			this.controlPoints[i] = new Vector4(point.x, point.y, point.z, point.w);

		}

	}

	override public function getPoint(t:Float, optionalTarget:Vector3 = null):Vector3 {

		var point:Vector3 = (optionalTarget != null) ? optionalTarget : new Vector3();

		var u = this.knots[this.startKnot] + t * (this.knots[this.endKnot] - this.knots[this.startKnot]); // linear mapping t->u

		// following results in (wx, wy, wz, w) homogeneous point
		var hpoint = NURBSUtils.calcBSplinePoint(this.degree, this.knots, this.controlPoints, u);

		if (hpoint.w != 1.0) {

			// project to 3D space: (wx, wy, wz, w) -> (x, y, z, 1)
			hpoint = hpoint.divideScalar(hpoint.w);

		}

		point.set(hpoint.x, hpoint.y, hpoint.z);
		return point;

	}

	override public function getTangent(t:Float, optionalTarget:Vector3 = null):Vector3 {

		var tangent:Vector3 = (optionalTarget != null) ? optionalTarget : new Vector3();

		var u = this.knots[0] + t * (this.knots[this.knots.length - 1] - this.knots[0]);
		var ders = NURBSUtils.calcNURBSDerivatives(this.degree, this.knots, this.controlPoints, u, 1);
		tangent.copy(ders[1]).normalize();

		return tangent;

	}

}