import three.math.Vector3;
import three.math.Vector4;

/**
 * NURBS utils
 *
 * See NURBSCurve and NURBSSurface.
 **/


/**************************************************************
 *	NURBS Utils
 **************************************************************/

/*
Finds knot vector span.

p : degree
u : parametric value
U : knot vector

returns the span
*/
function findSpan(p:Int, u:Float, U:Array<Float>):Int {

	var n = U.length - p - 1;

	if (u >= U[n]) {

		return n - 1;

	}

	if (u <= U[p]) {

		return p;

	}

	var low = p;
	var high = n;
	var mid = Math.floor((low + high) / 2);

	while (u < U[mid] || u >= U[mid + 1]) {

		if (u < U[mid]) {

			high = mid;

		} else {

			low = mid;

		}

		mid = Math.floor((low + high) / 2);

	}

	return mid;

}


/*
Calculate basis functions. See The NURBS Book, page 70, algorithm A2.2

span : span in which u lies
u    : parametric point
p    : degree
U    : knot vector

returns array[p+1] with basis functions values.
*/
function calcBasisFunctions(span:Int, u:Float, p:Int, U:Array<Float>):Array<Float> {

	var N = new Array<Float>(p + 1);
	var left = new Array<Float>(p + 1);
	var right = new Array<Float>(p + 1);
	N[0] = 1.0;

	for (var j = 1; j <= p; ++j) {

		left[j] = u - U[span + 1 - j];
		right[j] = U[span + j] - u;

		var saved = 0.0;

		for (var r = 0; r < j; ++r) {

			var rv = right[r + 1];
			var lv = left[j - r];
			var temp = N[r] / (rv + lv);
			N[r] = saved + rv * temp;
			saved = lv * temp;

		}

		N[j] = saved;

	}

	return N;

}


/*
Calculate B-Spline curve points. See The NURBS Book, page 82, algorithm A3.1.

p : degree of B-Spline
U : knot vector
P : control points (x, y, z, w)
u : parametric point

returns point for given u
*/
function calcBSplinePoint(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float):Vector4 {

	var span = findSpan(p, u, U);
	var N = calcBasisFunctions(span, u, p, U);
	var C = new Vector4(0, 0, 0, 0);

	for (var j = 0; j <= p; ++j) {

		var point = P[span - p + j];
		var Nj = N[j];
		var wNj = point.w * Nj;
		C.x += point.x * wNj;
		C.y += point.y * wNj;
		C.z += point.z * wNj;
		C.w += point.w * Nj;

	}

	return C;

}


/*
Calculate basis functions derivatives. See The NURBS Book, page 72, algorithm A2.3.

span : span in which u lies
u    : parametric point
p    : degree
n    : number of derivatives to calculate
U    : knot vector

returns array[n+1][p+1] with basis functions derivatives
*/
function calcBasisFunctionDerivatives(span:Int, u:Float, p:Int, n:Int, U:Array<Float>):Array<Array<Float>> {

	var zeroArr = new Array<Float>(p + 1);
	for (var i = 0; i <= p; ++i)
		zeroArr[i] = 0.0;

	var ders = new Array<Array<Float>>(n + 1);

	for (var i = 0; i <= n; ++i)
		ders[i] = zeroArr.copy();

	var ndu = new Array<Array<Float>>(p + 1);

	for (var i = 0; i <= p; ++i)
		ndu[i] = zeroArr.copy();

	ndu[0][0] = 1.0;

	var left = zeroArr.copy();
	var right = zeroArr.copy();

	for (var j = 1; j <= p; ++j) {

		left[j] = u - U[span + 1 - j];
		right[j] = U[span + j] - u;

		var saved = 0.0;

		for (var r = 0; r < j; ++r) {

			var rv = right[r + 1];
			var lv = left[j - r];
			ndu[j][r] = rv + lv;

			var temp = ndu[r][j - 1] / ndu[j][r];
			ndu[r][j] = saved + rv * temp;
			saved = lv * temp;

		}

		ndu[j][j] = saved;

	}

	for (var j = 0; j <= p; ++j) {

		ders[0][j] = ndu[j][p];

	}

	for (var r = 0; r <= p; ++r) {

		var s1 = 0;
		var s2 = 1;

		var a = new Array<Array<Float>>(p + 1);
		for (var i = 0; i <= p; ++i) {

			a[i] = zeroArr.copy();

		}

		a[0][0] = 1.0;

		for (var k = 1; k <= n; ++k) {

			var d = 0.0;
			var rk = r - k;
			var pk = p - k;

			if (r >= k) {

				a[s2][0] = a[s1][0] / ndu[pk + 1][rk];
				d = a[s2][0] * ndu[rk][pk];

			}

			var j1 = (rk >= - 1) ? 1 : - rk;
			var j2 = (r - 1 <= pk) ? k - 1 : p - r;

			for (var j = j1; j <= j2; ++j) {

				a[s2][j] = (a[s1][j] - a[s1][j - 1]) / ndu[pk + 1][rk + j];
				d += a[s2][j] * ndu[rk + j][pk];

			}

			if (r <= pk) {

				a[s2][k] = - a[s1][k - 1] / ndu[pk + 1][r];
				d += a[s2][k] * ndu[r][pk];

			}

			ders[k][r] = d;

			var j = s1;
			s1 = s2;
			s2 = j;

		}

	}

	var r = p;

	for (var k = 1; k <= n; ++k) {

		for (var j = 0; j <= p; ++j) {

			ders[k][j] *= r;

		}

		r *= p - k;

	}

	return ders;

}


/*
	Calculate derivatives of a B-Spline. See The NURBS Book, page 93, algorithm A3.2.

	p  : degree
	U  : knot vector
	P  : control points
	u  : Parametric points
	nd : number of derivatives

	returns array[d+1] with derivatives
	*/
function calcBSplineDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector4> {

	var du = nd < p ? nd : p;
	var CK = new Array<Vector4>(nd + 1);
	var span = findSpan(p, u, U);
	var nders = calcBasisFunctionDerivatives(span, u, p, du, U);
	var Pw = new Array<Vector4>(P.length);

	for (var i = 0; i < P.length; ++i) {

		var point = P[i].clone();
		var w = point.w;

		point.x *= w;
		point.y *= w;
		point.z *= w;

		Pw[i] = point;

	}

	for (var k = 0; k <= du; ++k) {

		var point = Pw[span - p].clone().multiplyScalar(nders[k][0]);

		for (var j = 1; j <= p; ++j) {

			point.add(Pw[span - p + j].clone().multiplyScalar(nders[k][j]));

		}

		CK[k] = point;

	}

	for (var k = du + 1; k <= nd + 1; ++k) {

		CK[k] = new Vector4(0, 0, 0);

	}

	return CK;

}


/*
Calculate "K over I"

returns k!/(i!(k-i)!)
*/
function calcKoverI(k:Int, i:Int):Float {

	var nom = 1;

	for (var j = 2; j <= k; ++j) {

		nom *= j;

	}

	var denom = 1;

	for (var j = 2; j <= i; ++j) {

		denom *= j;

	}

	for (var j = 2; j <= k - i; ++j) {

		denom *= j;

	}

	return nom / denom;

}


/*
Calculate derivatives (0-nd) of rational curve. See The NURBS Book, page 127, algorithm A4.2.

Pders : result of function calcBSplineDerivatives

returns array with derivatives for rational curve.
*/
function calcRationalCurveDerivatives(Pders:Array<Vector4>):Array<Vector3> {

	var nd = Pders.length;
	var Aders = new Array<Vector3>(nd);
	var wders = new Array<Float>(nd);

	for (var i = 0; i < nd; ++i) {

		var point = Pders[i];
		Aders[i] = new Vector3(point.x, point.y, point.z);
		wders[i] = point.w;

	}

	var CK = new Array<Vector3>(nd);

	for (var k = 0; k < nd; ++k) {

		var v = Aders[k].clone();

		for (var i = 1; i <= k; ++i) {

			v.sub(CK[k - i].clone().multiplyScalar(calcKoverI(k, i) * wders[i]));

		}

		CK[k] = v.divideScalar(wders[0]);

	}

	return CK;

}


/*
Calculate NURBS curve derivatives. See The NURBS Book, page 127, algorithm A4.2.

p  : degree
U  : knot vector
P  : control points in homogeneous space
u  : parametric points
nd : number of derivatives

returns array with derivatives.
*/
function calcNURBSDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector3> {

	var Pders = calcBSplineDerivatives(p, U, P, u, nd);
	return calcRationalCurveDerivatives(Pders);

}


/*
Calculate rational B-Spline surface point. See The NURBS Book, page 134, algorithm A4.3.

p, q : degrees of B-Spline surface
U, V : knot vectors
P    : control points (x, y, z, w)
u, v : parametric values

returns point for given (u, v)
*/
function calcSurfacePoint(p:Int, q:Int, U:Array<Float>, V:Array<Float>, P:Array<Array<Vector4>>, u:Float, v:Float, target:Vector3):Void {

	var uspan = findSpan(p, u, U);
	var vspan = findSpan(q, v, V);
	var Nu = calcBasisFunctions(uspan, u, p, U);
	var Nv = calcBasisFunctions(vspan, v, q, V);
	var temp = new Array<Vector4>(q + 1);

	for (var l = 0; l <= q; ++l) {

		temp[l] = new Vector4(0, 0, 0, 0);
		for (var k = 0; k <= p; ++k) {

			var point = P[uspan - p + k][vspan - q + l].clone();
			var w = point.w;
			point.x *= w;
			point.y *= w;
			point.z *= w;
			temp[l].add(point.multiplyScalar(Nu[k]));

		}

	}

	var Sw = new Vector4(0, 0, 0, 0);
	for (var l = 0; l <= q; ++l) {

		Sw.add(temp[l].multiplyScalar(Nv[l]));

	}

	Sw.divideScalar(Sw.w);
	target.set(Sw.x, Sw.y, Sw.z);

}

/*
Calculate rational B-Spline volume point. See The NURBS Book, page 134, algorithm A4.3.

p, q, r   : degrees of B-Splinevolume
U, V, W   : knot vectors
P         : control points (x, y, z, w)
u, v, w   : parametric values

returns point for given (u, v, w)
*/
function calcVolumePoint(p:Int, q:Int, r:Int, U:Array<Float>, V:Array<Float>, W:Array<Float>, P:Array<Array<Array<Vector4>>>, u:Float, v:Float, w:Float, target:Vector3):Void {

	var uspan = findSpan(p, u, U);
	var vspan = findSpan(q, v, V);
	var wspan = findSpan(r, w, W);
	var Nu = calcBasisFunctions(uspan, u, p, U);
	var Nv = calcBasisFunctions(vspan, v, q, V);
	var Nw = calcBasisFunctions(wspan, w, r, W);
	var temp = new Array<Array<Vector4>>(r + 1);

	for (var m = 0; m <= r; ++m) {

		temp[m] = new Array<Vector4>(q + 1);

		for (var l = 0; l <= q; ++l) {

			temp[m][l] = new Vector4(0, 0, 0, 0);
			for (var k = 0; k <= p; ++k) {

				var point = P[uspan - p + k][vspan - q + l][wspan - r + m].clone();
				var w = point.w;
				point.x *= w;
				point.y *= w;
				point.z *= w;
				temp[m][l].add(point.multiplyScalar(Nu[k]));

			}

		}

	}
	var Sw = new Vector4(0, 0, 0, 0);
	for (var m = 0; m <= r; ++m) {
		for (var l = 0; l <= q; ++l) {

			Sw.add(temp[m][l].multiplyScalar(Nw[m]).multiplyScalar(Nv[l]));

		}
	}

	Sw.divideScalar(Sw.w);
	target.set(Sw.x, Sw.y, Sw.z);

}

class Array<T> {

	public function copy():Array<T> {
		var copy = new Array<T>();
		for (i in 0...this.length) copy.push(this[i]);
		return copy;
	}

}