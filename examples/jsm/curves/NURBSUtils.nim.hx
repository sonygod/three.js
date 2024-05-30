import three.Vector3;
import three.Vector4;

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
function findSpan( p:Int, u:Float, U:Array<Float> ):Int {

	const n = U.length - p - 1;

	if ( u >= U[ n ] ) {

		return n - 1;

	}

	if ( u <= U[ p ] ) {

		return p;

	}

	var low = p;
	var high = n;
	var mid = Math.floor( ( low + high ) / 2 );

	while ( u < U[ mid ] || u >= U[ mid + 1 ] ) {

		if ( u < U[ mid ] ) {

			high = mid;

		} else {

			low = mid;

		}

		mid = Math.floor( ( low + high ) / 2 );

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
function calcBasisFunctions( span:Int, u:Float, p:Int, U:Array<Float> ):Array<Float> {

	const N = [];
	const left = [];
	const right = [];
	N[ 0 ] = 1.0;

	for ( i in 1...p + 1 ) {

		left[ i ] = u - U[ span + 1 - i ];
		right[ i ] = U[ span + i ] - u;

		var saved = 0.0;

		for ( j in 0...i ) {

			const rv = right[ j + 1 ];
			const lv = left[ i - j ];
			const temp = N[ j ] / ( rv + lv );
			N[ j ] = saved + rv * temp;
			saved = lv * temp;

		}

		N[ i ] = saved;

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
function calcBSplinePoint( p:Int, U:Array<Float>, P:Array<Vector4>, u:Float ):Vector4 {

	const span = findSpan( p, u, U );
	const N = calcBasisFunctions( span, u, p, U );
	const C = new Vector4( 0, 0, 0, 0 );

	for ( j in 0...p + 1 ) {

		const point = P[ span - p + j ];
		const Nj = N[ j ];
		const wNj = point.w * Nj;
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
function calcBasisFunctionDerivatives( span:Int, u:Float, p:Int, n:Int, U:Array<Float> ):Array<Array<Float>> {

	const zeroArr = [];
	for ( i in 0...p + 1 )
		zeroArr[ i ] = 0.0;

	const ders = [];

	for ( i in 0...n + 1 )
		ders[ i ] = zeroArr.slice( 0 );

	const ndu = [];

	for ( i in 0...p + 1 )
		ndu[ i ] = zeroArr.slice( 0 );

	ndu[ 0 ][ 0 ] = 1.0;

	const left = zeroArr.slice( 0 );
	const right = zeroArr.slice( 0 );

	for ( j in 1...p + 1 ) {

		left[ j ] = u - U[ span + 1 - j ];
		right[ j ] = U[ span + j ] - u;

		var saved = 0.0;

		for ( r in 0...j ) {

			const rv = right[ r + 1 ];
			const lv = left[ j - r ];
			ndu[ j ][ r ] = rv + lv;

			const temp = ndu[ r ][ j - 1 ] / ndu[ j ][ r ];
			ndu[ r ][ j ] = saved + rv * temp;
			saved = lv * temp;

		}

		ndu[ j ][ j ] = saved;

	}

	for ( j in 0...p + 1 ) {

		ders[ 0 ][ j ] = ndu[ j ][ p ];

	}

	for ( r in 0...p + 1 ) {

		var s1 = 0;
		var s2 = 1;

		const a = [];
		for ( i in 0...p + 1 ) {

			a[ i ] = zeroArr.slice( 0 );

		}

		a[ 0 ][ 0 ] = 1.0;

		for ( k in 1...n + 1 ) {

			var d = 0.0;
			const rk = r - k;
			const pk = p - k;

			if ( r >= k ) {

				a[ s2 ][ 0 ] = a[ s1 ][ 0 ] / ndu[ pk + 1 ][ rk ];
				d = a[ s2 ][ 0 ] * ndu[ rk ][ pk ];

			}

			const j1 = ( rk >= - 1 ) ? 1 : - rk;
			const j2 = ( r - 1 <= pk ) ? k - 1 : p - r;

			for ( j in j1...j2 + 1 ) {

				a[ s2 ][ j ] = ( a[ s1 ][ j ] - a[ s1 ][ j - 1 ] ) / ndu[ pk + 1 ][ rk + j ];
				d += a[ s2 ][ j ] * ndu[ rk + j ][ pk ];

			}

			if ( r <= pk ) {

				a[ s2 ][ k ] = - a[ s1 ][ k - 1 ] / ndu[ pk + 1 ][ r ];
				d += a[ s2 ][ k ] * ndu[ r ][ pk ];

			}

			ders[ k ][ r ] = d;

			const j = s1;
			s1 = s2;
			s2 = j;

		}

	}

	var r = p;

	for ( k in 1...n + 1 ) {

		for ( j in 0...p + 1 ) {

			ders[ k ][ j ] *= r;

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
function calcBSplineDerivatives( p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int ):Array<Vector4> {

	const du = nd < p ? nd : p;
	const CK = [];
	const span = findSpan( p, u, U );
	const nders = calcBasisFunctionDerivatives( span, u, p, du, U );
	const Pw = [];

	for ( i in 0...P.length ) {

		const point = P[ i ].clone();
		const w = point.w;

		point.x *= w;
		point.y *= w;
		point.z *= w;

		Pw[ i ] = point;

	}

	for ( k in 0...du + 1 ) {

		const point = Pw[ span - p ].clone().multiplyScalar( nders[ k ][ 0 ] );

		for ( j in 1...p + 1 ) {

			point.add( Pw[ span - p + j ].clone().multiplyScalar( nders[ k ][ j ] ) );

		}

		CK[ k ] = point;

	}

	for ( k in du + 1...nd + 1 ) {

		CK[ k ] = new Vector4( 0, 0, 0 );

	}

	return CK;

}


/*
Calculate "K over I"

returns k!/(i!(k-i)!)
*/
function calcKoverI( k:Int, i:Int ):Float {

	var nom = 1;

	for ( j in 2...k + 1 ) {

		nom *= j;

	}

	var denom = 1;

	for ( j in 2...i + 1 ) {

		denom *= j;

	}

	for ( j in 2...k - i + 1 ) {

		denom *= j;

	}

	return nom / denom;

}


/*
Calculate derivatives (0-nd) of rational curve. See The NURBS Book, page 127, algorithm A4.2.

Pders : result of function calcBSplineDerivatives

returns array with derivatives for rational curve.
*/
function calcRationalCurveDerivatives( Pders:Array<Vector4> ):Array<Vector3> {

	const nd = Pders.length;
	const Aders = [];
	const wders = [];

	for ( i in 0...nd ) {

		const point = Pders[ i ];
		Aders[ i ] = new Vector3( point.x, point.y, point.z );
		wders[ i ] = point.w;

	}

	const CK = [];

	for ( k in 0...nd ) {

		const v = Aders[ k ].clone();

		for ( i in 1...k + 1 ) {

			v.sub( CK[ k - i ].clone().multiplyScalar( calcKoverI( k, i ) * wders[ i ] ) );

		}

		CK[ k ] = v.divideScalar( wders[ 0 ] );

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
function calcNURBSDerivatives( p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int ):Array<Vector3> {

	const Pders = calcBSplineDerivatives( p, U, P, u, nd );
	return calcRationalCurveDerivatives( Pders );

}


/*
Calculate rational B-Spline surface point. See The NURBS Book, page 134, algorithm A4.3.

p, q : degrees of B-Spline surface
U, V : knot vectors
P    : control points (x, y, z, w)
u, v : parametric values

returns point for given (u, v)
*/
function calcSurfacePoint( p:Int, q:Int, U:Array<Float>, V:Array<Float>, P:Array<Array<Vector4>>, u:Float, v:Float, target:Vector3 ):Void {

	const uspan = findSpan( p, u, U );
	const vspan = findSpan( q, v, V );
	const Nu = calcBasisFunctions( uspan, u, p, U );
	const Nv = calcBasisFunctions( vspan, v, q, V );
	const temp = [];

	for ( l in 0...q + 1 ) {

		temp[ l ] = new Vector4( 0, 0, 0, 0 );
		for ( k in 0...p + 1 ) {

			const point = P[ uspan - p + k ][ vspan - q + l ].clone();
			const w = point.w;
			point.x *= w;
			point.y *= w;
			point.z *= w;
			temp[ l ].add( point.multiplyScalar( Nu[ k ] ) );

		}

	}

	const Sw = new Vector4( 0, 0, 0, 0 );
	for ( l in 0...q + 1 ) {

		Sw.add( temp[ l ].multiplyScalar( Nv[ l ] ) );

	}

	Sw.divideScalar( Sw.w );
	target.set( Sw.x, Sw.y, Sw.z );

}

/*
Calculate rational B-Spline volume point. See The NURBS Book, page 134, algorithm A4.3.

p, q, r   : degrees of B-Splinevolume
U, V, W   : knot vectors
P         : control points (x, y, z, w)
u, v, w   : parametric values

returns point for given (u, v, w)
*/
function calcVolumePoint( p:Int, q:Int, r:Int, U:Array<Float>, V:Array<Float>, W:Array<Float>, P:Array<Array<Array<Vector4>>>, u:Float, v:Float, w:Float, target:Vector3 ):Void {

	const uspan = findSpan( p, u, U );
	const vspan = findSpan( q, v, V );
	const wspan = findSpan( r, w, W );
	const Nu = calcBasisFunctions( uspan, u, p, U );
	const Nv = calcBasisFunctions( vspan, v, q, V );
	const Nw = calcBasisFunctions( wspan, w, r, W );
	const temp = [];

	for ( m in 0...r + 1 ) {

		temp[ m ] = [];

		for ( l in 0...q + 1 ) {

			temp[ m ][ l ] = new Vector4( 0, 0, 0, 0 );
			for ( k in 0...p + 1 ) {

				const point = P[ uspan - p + k ][ vspan - q + l ][ wspan - r + m ].clone();
				const w = point.w;
				point.x *= w;
				point.y *= w;
				point.z *= w;
				temp[ m ][ l ].add( point.multiplyScalar( Nu[ k ] ) );

			}

		}

	}
	const Sw = new Vector4( 0, 0, 0, 0 );
	for ( m in 0...r + 1 ) {
		for ( l in 0...q + 1 ) {

			Sw.add( temp[ m ][ l ].multiplyScalar( Nw[ m ] ).multiplyScalar( Nv[ l ] ) );

		}
	}

	Sw.divideScalar( Sw.w );
	target.set( Sw.x, Sw.y, Sw.z );

}


export {
	findSpan,
	calcBasisFunctions,
	calcBSplinePoint,
	calcBasisFunctionDerivatives,
	calcBSplineDerivatives,
	calcKoverI,
	calcRationalCurveDerivatives,
	calcNURBSDerivatives,
	calcSurfacePoint,
	calcVolumePoint,
};