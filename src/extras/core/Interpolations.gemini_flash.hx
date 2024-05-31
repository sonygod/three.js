/**
 * Bezier Curves formulas obtained from
 * https://en.wikipedia.org/wiki/B%C3%A9zier_curve
 */

function CatmullRom( t:Float, p0:Float, p1:Float, p2:Float, p3:Float ):Float {

	var v0 = ( p2 - p0 ) * 0.5;
	var v1 = ( p3 - p1 ) * 0.5;
	var t2 = t * t;
	var t3 = t * t2;
	return ( 2 * p1 - 2 * p2 + v0 + v1 ) * t3 + ( - 3 * p1 + 3 * p2 - 2 * v0 - v1 ) * t2 + v0 * t + p1;

}

//

function QuadraticBezierP0( t:Float, p:Float ):Float {

	var k = 1 - t;
	return k * k * p;

}

function QuadraticBezierP1( t:Float, p:Float ):Float {

	return 2 * ( 1 - t ) * t * p;

}

function QuadraticBezierP2( t:Float, p:Float ):Float {

	return t * t * p;

}

function QuadraticBezier( t:Float, p0:Float, p1:Float, p2:Float ):Float {

	return QuadraticBezierP0( t, p0 ) + QuadraticBezierP1( t, p1 ) +
		QuadraticBezierP2( t, p2 );

}

//

function CubicBezierP0( t:Float, p:Float ):Float {

	var k = 1 - t;
	return k * k * k * p;

}

function CubicBezierP1( t:Float, p:Float ):Float {

	var k = 1 - t;
	return 3 * k * k * t * p;

}

function CubicBezierP2( t:Float, p:Float ):Float {

	return 3 * ( 1 - t ) * t * t * p;

}

function CubicBezierP3( t:Float, p:Float ):Float {

	return t * t * t * p;

}

function CubicBezier( t:Float, p0:Float, p1:Float, p2:Float, p3:Float ):Float {

	return CubicBezierP0( t, p0 ) + CubicBezierP1( t, p1 ) + CubicBezierP2( t, p2 ) +
		CubicBezierP3( t, p3 );

}

class Interpolations {

	public static var CatmullRom : ( t:Float, p0:Float, p1:Float, p2:Float, p3:Float )->Float = CatmullRom;
	public static var QuadraticBezier : ( t:Float, p0:Float, p1:Float, p2:Float )->Float = QuadraticBezier;
	public static var CubicBezier : ( t:Float, p0:Float, p1:Float, p2:Float, p3:Float )->Float = CubicBezier;
}