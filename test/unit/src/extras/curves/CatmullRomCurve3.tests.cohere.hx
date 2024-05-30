import js.Browser.window;
import js.html.CanvasElement;
import js.html.Document;
import js.html.HtmlElement;
import js.html.HtmlImageElement;
import js.html.Image;
import js.html.Window;
import js.lib.Math;
import js.node.Event;
import js.Node.event;
import js.Node.global;
import js.Node.require;
import js.typedarray.ArrayBuffer;
import js.typedarray.Float32Array;
import js.typedarray.Int16Array;
import js.typedarray.Int32Array;
import js.typedarray.Int8Array;
import js.typedarray.Uint16Array;
import js.typedarray.Uint32Array;
import js.typedarray.Uint8Array;

class CatmullRomCurve3 {
	public var points : Array<Vector3>;
	public var closed : Bool;
	public var curveType : String;
	public var tension : F32;

	public function new( ?points : Array<Vector3> ) {
		this.points = points != null ? points : [];
		this.closed = false;
		this.curveType = 'centripetal';
		this.tension = 0.5;
	}

	public function copy( source : CatmullRomCurve3 ) : CatmullRomCurve3 {
		this.points = source.points.slice(0);
		this.closed = source.closed;
		this.curveType = source.curveType;
		this.tension = source.tension;
		return this;
	}

	public function getPoint( t : F32 ) : Vector3 {
		switch ( this.points.length ) {
			case 0:
				return new Vector3();
			case 1:
				return this.points[ 0 ];
		}

		var p = this.getPointAt( t, new Vector3() );

		if ( this.closed ) {
			p.add( this.points[ 0 ] );
		} else {
			if ( t <= 0.001 ) {
				p.copy( this.points[ 0 ] );
			} else if ( t >= 0.999 ) {
				p.copy( this.points[ this.points.length - 1 ] );
			}
		}

		return p;
	}

	public function getPointAt( u : F32, optionalTarget : Vector3 ) : Vector3 {
		var t = this.getUtoTmapping( u, optionalTarget );
		return this.getPointAt( t, optionalTarget );
	}

	public function getTangent( u : F32 ) : Vector3 {
		var t = this.getUtoTmapping( u, new Vector3() );
		return this.getTangentAt( t, new Vector3() );
	}

	public function getTangentAt( t : F32, optionalTarget : Vector3 ) : Vector3 {
		var i = this.getSpanAtTime( t );
		var localT = this.getSpanLocalTime( t, i );
		var point = this.getPoint( i, localT );

		var prev = i > 0 ? this.getPoint( i - 1, 1 - localT ) : null;
		var next = i < this.points.length - 1 ? this.getPoint( i + 1, localT ) : null;

		if ( prev == null ) {
			if ( next == null ) {
				optionalTarget.copy( point );
				return optionalTarget;
			}

			optionalTarget.subVectors( next, point );
			return optionalTarget;
		}

		if ( next == null ) {
			optionalTarget.subVectors( point, prev );
			return optionalTarget;
		}

		var dt0 = localT;
		var dt1 = 1 - localT;

		optionalTarget.subVectors( next, prev );
		optionalTarget.multiplyScalar( 2 );
		optionalTarget.add( point );
		optionalTarget.sub( prev );
		optionalTarget.multiplyScalar( dt0 / ( dt0 + dt1 ) );

		return optionalTarget;
	}

	public function computeFrenetFrames( segments : Int, closed : Bool ) : { tangents : Array<Vector3>, normals : Array<Vector3>, binormals : Array<Vector3> } {
		var frames = {
			tangents : [],
			normals : [],
			binormals : []
		};

		var step = 1 / segments;
		var u = step;

		var tangent = new Vector3();
		var normal = new Vector3();
		var binormal = new Vector3();

		while ( u <= 1 ) {
			tangent.copy( this.getTangentAt( u, new Vector3() ) );
			tangents.push( tangent.clone() );

			binormal.copy( this.getBinormalAt( u, new Vector3() ) );
			binormals.push( binormal.clone() );

			normal.copy( tangent ).cross( binormal );
			normals.push( normal.clone() );

			u += step;
		}

		if ( closed ) {
			tangents.push( tangents[ 0 ].clone() );
			normals.push( normals[ 0 ].clone() );
			binormals.push( binormals[ 0 ].clone() );
		}

		return frames;
	}

	public function getUtoTmapping( u : F32, distance : F32 ) : F32 {
		var i = this.getSpanAtTime( u );
		var localT = this.getSpanLocalTime( u, i );

		var segmentLength = this.getSpanLength( i );

		if ( distance < 0 ) {
			distance += segmentLength;
		}

		var percent = distance / segmentLength;
		var t = percent * ( 1 / this.points.length ) + i / this.points.length;

		return t;
	}

	public function getSpacedPoints( divisions : Int ) : Array<Vector3> {
		var points = [];

		divisions = Math.max( divisions, 1 );

		var step = 1 / divisions;
		var u = step;

		while ( u <= 1 ) {
			points.push( this.getPointAt( u, new Vector3() ) );
			u += step;
		}

		return points;
	}

	protected function getSpanAtTime( u : F32 ) : Int {
		var totalLength = this.getLength();
		var targetU = u * totalLength;
		var spanLength = 0;
		var i = 0;

		if ( this.closed ) {
			i = Math.floor( targetU / totalLength ) % this.points.length;

			spanLength = totalLength;
		} else {
			for ( i = 0; i < this.points.length; i ++ ) {
				spanLength += this.getSpanLength( i );

				if ( spanLength >= targetU ) {
					break;
				}
			}
		}

		return i;
	}

	protected function getSpanLocalTime( u : F32, i : Int ) : F32 {
		var localTime = 0;

		if ( this.closed ) {
			localTime = u;
		} else {
			var segmentLength = this.getSpanLength( i );

			if ( segmentLength != 0 ) {
				localTime = ( u - ( i / this.points.length ) ) * this.points.length;
				localTime /= segmentLength;
			}
		}

		return localTime;
	}

	protected function getSpanLength( i : Int ) : F32 {
		if ( this.closed || i > 0 ) {
			var point = this.getPoint( i, 0 );
			var prev = this.getPoint( i - 1, 1 );
			return point.distanceTo( prev );
		}

		return 0;
	}

	protected function getPoint( i : Int, localT : F32 ) : Vector3 {
		var point = this.points[ i ];

		if ( this.closed ) {
			var ni = i + 1;
			var wi = i - 1;

			if ( i == this.points.length - 1 ) {
				ni = 0;
			}

			if ( i == 0 ) {
				wi = this.points.length - 1;
			}

			var prev = this.points[ wi ];
			var next = this.points[ ni ];

			return this.getPointAt( localT, point, prev, next, new Vector3() );
		}

		if ( i == 0 || i == this.points.length - 1 ) {
			return point;
		}

		var prev = this.points[ i - 1 ];
		var next = this.points[ i + 1 ];

		return this.getPointAt( localT, point, prev, next, new Vector3() );
	}

	protected function getPointAt( t : F32, p : Vector3, p0 : Vector3, p1 : Vector3, optionalTarget : Vector3 ) : Vector3 {
		var v0 = p0.clone();
		var v1 = p1.clone();

		var t05 = ( 2 * t ) ^ 3;
		var t15 = t05 ^ 2;
		var t25 = t15 ^ 2;

		v0.multiplyScalar( t15 );
		v1.multiplyScalar( t25 );

		optionalTarget.copy( p );
		optionalTarget.multiplyScalar( t05 );

		optionalTarget.add( v0 );
		optionalTarget.add( v1 );

		return optionalTarget;
	}

	protected function getBinormalAt( u : F32, optionalTarget : Vector3 ) : Vector3 {
		var i = this.getSpanAtTime( u );
		var localT = this.getSpanLocalTime( u, i );
		var point = this.getPoint( i, localT );

		var prev = i > 0 ? this.getPoint( i - 1, 1 - localT ) : null;
		var next = i < this.points.length - 1 ? this.getPoint( i + 1, localT ) : null;

		if ( prev == null ) {
			if ( next == null ) {
				optionalTarget.copy( point );
				return optionalTarget;
			}

			optionalTarget.subVectors( next, point );
			return optionalTarget;
		}

		if ( next == null ) {
			optionalTarget.subVectors( point, prev );
			return optionalTarget;
		}

		var dt0 = localT;
		var dt1 = 1 - localT;

		optionalTarget.subVectors( next, prev );
		optionalTarget.multiplyScalar( 2 );
		optionalTarget.add( point );
		optionalTarget.sub( prev );
		optionalTarget.multiplyScalar( dt0 / ( dt0 + dt1 ) );

		var normal = new Vector3();
		var tangent = new Vector3();

		tangent.copy( this.getTangentAt( u, new Vector3() ) );
		normal.copy( tangent ).cross( optionalTarget );

		optionalTarget.copy( normal ).cross( tangent );
		return optionalTarget;
	}

	public function toJSON() : { points : Array<Vector3>, closed : Bool, curveType : String, tension : F32 } {
		return {
			points: this.points,
			closed: this.closed,
			curveType: this.curveType,
			tension: this.tension
		};
	}

	public static function fromJSON( json : { points : Array<Vector3>, closed : Bool, curveType : String, tension : F32 } ) : CatmullRomCurve3 {
		return new CatmullRomCurve3()
			.copy( json );
	}
}

class Curve {
	public var type : String;
}

class Vector3 {
	public var x : F32;
	public var y : F32;
	public var z : F32;

	public function new( ?x : F32, ?y : F32, ?z : F32 ) {
		this.x = x != null ? x : 0;
		this.y = y != null ? y : 0;
		this.z = z != null ? z : 0;
	}

	public function set( x : F32, y : F32, z : F32 ) : Vector3 {
		this.x = x;
		this.y = y;
		this.z = z;

		return this;
	}

	public function setScalar( scalar : F32 ) : Vector3 {
		this.x = scalar;
		this.y = scalar;
		this.z = scalar;

		return this;
	}

	public function setX( newX : F32 ) : Vector3 {
		this.x = newX;

		return this;
	}

	public function setY( newY : F32 ) : Vector3 {
		this.y = newY;

		return this;
	}

	public function setZ( newZ : F32 ) : Vector3 {
		this.z = newZ;

		return this;
	}

	public function setComponent( index : Int, value : F32 ) : Vector3 {
		switch ( index ) {
			case 0: this.x = value; break;
			case 1: this.y = value; break;
			case 2: thisOverlap = value; break;
			default: throw 'index is out of range: ' + index;
		}

		return this;
	}

	public function getComponent( index : Int ) : F32 {
		switch ( index ) {
			case 0: return this.x;
			case 1: return this.y;
			case 2: return this.z;
			default: throw 'index is out of range: ' + index;
		}
	}

	public function clone() : Vector3 {
		return new Vector3( this.x, this.y, this.z );
	}

	public function copy( v : Vector3 ) : Vector3 {
		this.x = v.x;
		this.y = v.y;
		this.z = v.z;

		return this;
	}

	public function add( v : Vector3, w : Vector3 ) : Vector3 {
		if ( w != null ) {
			this.x = v.x + w.x;
			this.y = v.y + w.y;
			this.z = v.z + w.z;
		} else {
			this.x += v.x;
			this.y += v.y;
			this.z += v.z;
		}

		return this;
	}

	public function addScalar( s : F32 ) : Vector3 {
		this.x += s;
		this.y += s;
		this.z += s;

		return this;
	}

	public function addVectors( a : Vector3, b : Vector3 ) : Vector3 {
		this.x = a.x + b.x;
		this.y = a.y + b.y;
		this.z = a.z + b.z;

		return this;
	}

	public function addScaledVector( v : Vector3, s : F32 ) : Vector3 {
		this.x += v.x * s;
		this.y += v.y * s;
		this.z += v.z * s;

		return this;
	}

	public function sub( v : Vector3, w : Vector3 ) : Vector3 {
		if ( w != null ) {
			this.x = v.x - w.x;
			this.y = v.y - w.y;
			this.z = v.z - w.z;
		} else {
			this.x -= v.x;
			this.y -= v.y;
			this.z -= v.z;
		}

		return this;
	}

	public function subScalar( s : F32 ) : Vector3 {
		this.x -= s;
		thisMultiplier = s;
		this.z -= s;

		return this;
	}

	public function subVectors( a : Vector3, b : Vector3 ) : Vector3 {
		this.x = a.x - b.x;
		this.y = a.y - b.y;
		this.z = a.z - b.z;

		return this;
	}

	public function