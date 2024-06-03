import Curve from "./Curve";
import Curves from "../curves/Curves";

/**************************************************************
 *	Curved Path - a curve path is simply a array of connected
 *  curves, but retains the api of a curve
 **************************************************************/

class CurvePath extends Curve {

	public curves:Array<Curve> = [];
	public autoClose:Bool = false; // Automatically closes the path

	public function new() {
		super();
		this.type = "CurvePath";
	}

	public function add(curve:Curve) {
		this.curves.push(curve);
	}

	public function closePath():CurvePath {
		// Add a line curve if start and end of lines are not connected
		var startPoint = this.curves[0].getPoint(0);
		var endPoint = this.curves[this.curves.length - 1].getPoint(1);
		if (!startPoint.equals(endPoint)) {
			var lineType = (startPoint.isVector2) ? "LineCurve" : "LineCurve3";
			this.curves.push(new Curves[lineType](endPoint, startPoint));
		}
		return this;
	}

	// To get accurate point with reference to
	// entire path distance at time t,
	// following has to be done:

	// 1. Length of each sub path have to be known
	// 2. Locate and identify type of curve
	// 3. Get t for the curve
	// 4. Return curve.getPointAt(t')

	public function getPoint(t:Float, optionalTarget:Dynamic = null):Dynamic {
		var d = t * this.getLength();
		var curveLengths = this.getCurveLengths();
		var i = 0;

		// To think about boundaries points.

		while (i < curveLengths.length) {
			if (curveLengths[i] >= d) {
				var diff = curveLengths[i] - d;
				var curve = this.curves[i];
				var segmentLength = curve.getLength();
				var u = (segmentLength == 0) ? 0 : 1 - diff / segmentLength;
				return curve.getPointAt(u, optionalTarget);
			}
			i++;
		}

		return null;

		// loop where sum != 0, sum > d , sum+1 <d
	}

	// We cannot use the default THREE.Curve getPoint() with getLength() because in
	// THREE.Curve, getLength() depends on getPoint() but in THREE.CurvePath
	// getPoint() depends on getLength

	public function getLength():Float {
		var lens = this.getCurveLengths();
		return lens[lens.length - 1];
	}

	// cacheLengths must be recalculated.
	public function updateArcLengths() {
		this.needsUpdate = true;
		this.cacheLengths = null;
		this.getCurveLengths();
	}

	// Compute lengths and cache them
	// We cannot overwrite getLengths() because UtoT mapping uses it.

	public function getCurveLengths():Array<Float> {
		// We use cache values if curves and cache array are same length

		if (this.cacheLengths != null && this.cacheLengths.length == this.curves.length) {
			return this.cacheLengths;
		}

		// Get length of sub-curve
		// Push sums into cached array

		var lengths = [];
		var sums = 0;

		for (i in 0...this.curves.length) {
			sums += this.curves[i].getLength();
			lengths.push(sums);
		}

		this.cacheLengths = lengths;

		return lengths;
	}

	public function getSpacedPoints(divisions:Int = 40):Array<Dynamic> {
		var points = [];

		for (i in 0...divisions + 1) {
			points.push(this.getPoint(i / divisions));
		}

		if (this.autoClose) {
			points.push(points[0]);
		}

		return points;
	}

	public function getPoints(divisions:Int = 12):Array<Dynamic> {
		var points = [];
		var last:Dynamic = null;

		for (i in 0...this.curves.length) {
			var curve = this.curves[i];
			var resolution = (curve.isEllipseCurve) ? divisions * 2 : (curve.isLineCurve || curve.isLineCurve3) ? 1 : (curve.isSplineCurve) ? divisions * curve.points.length : divisions;
			var pts = curve.getPoints(resolution);

			for (j in 0...pts.length) {
				var point = pts[j];

				if (last != null && last.equals(point)) continue; // ensures no consecutive points are duplicates

				points.push(point);
				last = point;
			}
		}

		if (this.autoClose && points.length > 1 && !points[points.length - 1].equals(points[0])) {
			points.push(points[0]);
		}

		return points;
	}

	public function copy(source:CurvePath):CurvePath {
		super.copy(source);

		this.curves = [];

		for (i in 0...source.curves.length) {
			var curve = source.curves[i];
			this.curves.push(curve.clone());
		}

		this.autoClose = source.autoClose;

		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();

		data.autoClose = this.autoClose;
		data.curves = [];

		for (i in 0...this.curves.length) {
			var curve = this.curves[i];
			data.curves.push(curve.toJSON());
		}

		return data;
	}

	public function fromJSON(json:Dynamic):CurvePath {
		super.fromJSON(json);

		this.autoClose = json.autoClose;
		this.curves = [];

		for (i in 0...json.curves.length) {
			var curve = json.curves[i];
			this.curves.push(new Curves[curve.type]().fromJSON(curve));
		}

		return this;
	}

}

export default CurvePath;