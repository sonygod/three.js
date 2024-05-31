import three.math.Vector3;
import three.extras.core.Curve;

/**
 * Centripetal CatmullRom Curve - which is useful for avoiding
 * cusps and self-intersections in non-uniform catmull rom curves.
 * http://www.cemyuksel.com/research/catmullrom_param/catmullrom.pdf
 *
 * curve.type accepts centripetal(default), chordal and catmullrom
 * curve.tension is used for catmullrom which defaults to 0.5
 */

class CubicPoly {

	public var c0:Float;
	public var c1:Float;
	public var c2:Float;
	public var c3:Float;

	public function new() {
		this.c0 = 0;
		this.c1 = 0;
		this.c2 = 0;
		this.c3 = 0;
	}

	/*
	 * Compute coefficients for a cubic polynomial
	 *   p(s) = c0 + c1*s + c2*s^2 + c3*s^3
	 * such that
	 *   p(0) = x0, p(1) = x1
	 *  and
	 *   p'(0) = t0, p'(1) = t1.
	 */
	public function init( x0:Float, x1:Float, t0:Float, t1:Float ):Void {

		this.c0 = x0;
		this.c1 = t0;
		this.c2 = - 3 * x0 + 3 * x1 - 2 * t0 - t1;
		this.c3 = 2 * x0 - 2 * x1 + t0 + t1;

	}

	public function initCatmullRom( x0:Float, x1:Float, x2:Float, x3:Float, tension:Float ):Void {

		init( x1, x2, tension * ( x2 - x0 ), tension * ( x3 - x1 ) );

	}

	public function initNonuniformCatmullRom( x0:Float, x1:Float, x2:Float, x3:Float, dt0:Float, dt1:Float, dt2:Float ):Void {

		// compute tangents when parameterized in [t1,t2]
		let t1 = ( x1 - x0 ) / dt0 - ( x2 - x0 ) / ( dt0 + dt1 ) + ( x2 - x1 ) / dt1;
		let t2 = ( x2 - x1 ) / dt1 - ( x3 - x1 ) / ( dt1 + dt2 ) + ( x3 - x2 ) / dt2;

		// rescale tangents for parametrization in [0,1]
		t1 *= dt1;
		t2 *= dt1;

		init( x1, x2, t1, t2 );

	}

	public function calc( t:Float ):Float {

		let t2 = t * t;
		let t3 = t2 * t;
		return c0 + c1 * t + c2 * t2 + c3 * t3;

	}

}

class CatmullRomCurve3 extends Curve {

	public var points:Array<Vector3>;
	public var closed:Bool;
	public var curveType:String;
	public var tension:Float;

	public function new( points:Array<Vector3> = [], closed:Bool = false, curveType:String = 'centripetal', tension:Float = 0.5 ) {
		super();
		this.points = points;
		this.closed = closed;
		this.curveType = curveType;
		this.tension = tension;
	}

	public function getPoint( t:Float, optionalTarget:Vector3 = new Vector3() ):Vector3 {

		let point = optionalTarget;

		let l = this.points.length;
		let p = ( l - ( this.closed ? 0 : 1 ) ) * t;
		let intPoint = Math.floor( p );
		let weight = p - intPoint;

		if ( this.closed ) {

			intPoint += intPoint > 0 ? 0 : ( Math.floor( Math.abs( intPoint ) / l ) + 1 ) * l;

		} else if ( weight === 0 && intPoint === l - 1 ) {

			intPoint = l - 2;
			weight = 1;

		}

		let p0:Vector3, p3:Vector3; // 4 points (p1 & p2 defined below)

		if ( this.closed || intPoint > 0 ) {

			p0 = this.points[ ( intPoint - 1 ) % l ];

		} else {

			// extrapolate first point
			let tmp = new Vector3();
			tmp.subVectors( this.points[ 0 ], this.points[ 1 ] ).add( this.points[ 0 ] );
			p0 = tmp;

		}

		let p1 = this.points[ intPoint % l ];
		let p2 = this.points[ ( intPoint + 1 ) % l ];

		if ( this.closed || intPoint + 2 < l ) {

			p3 = this.points[ ( intPoint + 2 ) % l ];

		} else {

			// extrapolate last point
			let tmp = new Vector3();
			tmp.subVectors( this.points[ l - 1 ], this.points[ l - 2 ] ).add( this.points[ l - 1 ] );
			p3 = tmp;

		}

		let px = new CubicPoly();
		let py = new CubicPoly();
		let pz = new CubicPoly();

		if ( this.curveType === 'centripetal' || this.curveType === 'chordal' ) {

			// init Centripetal / Chordal Catmull-Rom
			let pow = this.curveType === 'chordal' ? 0.5 : 0.25;
			let dt0 = Math.pow( p0.distanceToSquared( p1 ), pow );
			let dt1 = Math.pow( p1.distanceToSquared( p2 ), pow );
			let dt2 = Math.pow( p2.distanceToSquared( p3 ), pow );

			// safety check for repeated points
			if ( dt1 < 1e-4 ) dt1 = 1.0;
			if ( dt0 < 1e-4 ) dt0 = dt1;
			if ( dt2 < 1e-4 ) dt2 = dt1;

			px.initNonuniformCatmullRom( p0.x, p1.x, p2.x, p3.x, dt0, dt1, dt2 );
			py.initNonuniformCatmullRom( p0.y, p1.y, p2.y, p3.y, dt0, dt1, dt2 );
			pz.initNonuniformCatmullRom( p0.z, p1.z, p2.z, p3.z, dt0, dt1, dt2 );

		} else if ( this.curveType === 'catmullrom' ) {

			px.initCatmullRom( p0.x, p1.x, p2.x, p3.x, this.tension );
			py.initCatmullRom( p0.y, p1.y, p2.y, p3.y, this.tension );
			pz.initCatmullRom( p0.z, p1.z, p2.z, p3.z, this.tension );

		}

		point.set(
			px.calc( weight ),
			py.calc( weight ),
			pz.calc( weight )
		);

		return point;

	}

	public function copy( source:CatmullRomCurve3 ):CatmullRomCurve3 {

		super.copy( source );

		this.points = [];

		for ( i in 0...source.points.length ) {

			let point = source.points[ i ];
			this.points.push( point.clone() );

		}

		this.closed = source.closed;
		this.curveType = source.curveType;
		this.tension = source.tension;

		return this;

	}

	public function toJSON():Dynamic {

		let data = super.toJSON();

		data.points = [];

		for ( i in 0...this.points.length ) {

			let point = this.points[ i ];
			data.points.push( point.toArray() );

		}

		data.closed = this.closed;
		data.curveType = this.curveType;
		data.tension = this.tension;

		return data;

	}

	public function fromJSON( json:Dynamic ):CatmullRomCurve3 {

		super.fromJSON( json );

		this.points = [];

		for ( i in 0...json.points.length ) {

			let point = json.points[ i ];
			this.points.push( new Vector3().fromArray( point ) );

		}

		this.closed = json.closed;
		this.curveType = json.curveType;
		this.tension = json.tension;

		return this;

	}

}