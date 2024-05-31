package;

import haxe.extern.EitherType;
import js.lib.ArrayBufferView;
import js.lib.Float32Array;

#if (three_vector2_from_vector2 || three_vector2_to_vector2)
import three.THREE;
#end

@:native("THREE.Vector2") extern class Vector2 {

    #if three_vector2_from_vector2
    @:native("THREE.Vector2")
    static function fromVector2( v : THREE.Vector2 ) : Vector2;
    #end

    #if three_vector2_to_vector2
    @:native("v.clone()")
    function toVector2() : THREE.Vector2;
    #end

	static var prototype : Vector2;

	var x : Float;
	var y : Float;
	var width(get, set) : Float;
	var height(get, set) : Float;
	var isVector2 : Bool;

	function new( ?x : Float = 0, ?y : Float = 0 ) : Void;

	function set( x : Float, y : Float ) : Vector2;

	function setScalar( scalar : Float ) : Vector2;

	function setX( x : Float ) : Vector2;

	function setY( y : Float ) : Vector2;

	function setComponent( index : Int, value : Float ) : Vector2;

	function getComponent( index : Int ) : Float;

	function clone() : Vector2;

	function copy( v : Vector2 ) : Vector2;

	function add( v : Vector2 ) : Vector2;

	function addScalar( s : Float ) : Vector2;

	function addVectors( a : Vector2, b : Vector2 ) : Vector2;

	function addScaledVector( v : Vector2, s : Float ) : Vector2;

	function sub( v : Vector2 ) : Vector2;

	function subScalar( s : Float ) : Vector2;

	function subVectors( a : Vector2, b : Vector2 ) : Vector2;

	function multiply( v : Vector2 ) : Vector2;

	function multiplyScalar( scalar : Float ) : Vector2;

	function divide( v : Vector2 ) : Vector2;

	function divideScalar( scalar : Float ) : Vector2;

	function applyMatrix3( m : Matrix3 ) : Vector2;

	function min( v : Vector2 ) : Vector2;

	function max( v : Vector2 ) : Vector2;

	function clamp( min : Vector2, max : Vector2 ) : Vector2;

	function clampScalar( minVal : Float, maxVal : Float ) : Vector2;

	function clampLength( min : Float, max : Float ) : Vector2;

	function floor() : Vector2;

	function ceil() : Vector2;

	function round() : Vector2;

	function roundToZero() : Vector2;

	function negate() : Vector2;

	function dot( v : Vector2 ) : Float;

	function cross( v : Vector2 ) : Float;

	function lengthSq() : Float;

	function length() : Float;

	function manhattanLength() : Float;

	function normalize() : Vector2;

	function angle() : Float;

	function angleTo( v : Vector2 ) : Float;

	function distanceTo( v : Vector2 ) : Float;

	function distanceToSquared( v : Vector2 ) : Float;

	function manhattanDistanceTo( v : Vector2 ) : Float;

	function setLength( length : Float ) : Vector2;

	function lerp( v : Vector2, alpha : Float ) : Vector2;

	function lerpVectors( v1 : Vector2, v2 : Vector2, alpha : Float ) : Vector2;

	function equals( v : Vector2 ) : Bool;

	function fromArray( array : EitherType<Array<Float>, ArrayBufferView>, ?offset : Int = 0 ) : Vector2;

	function toArray( ?array : EitherType<Array<Float>, ArrayBufferView> = null, ?offset : Int = 0 ) : EitherType<Array<Float>, ArrayBufferView>;

	function fromBufferAttribute( attribute : { function getX( index : Int ) : Float; function getY( index : Int) : Float; }, index : Int ) : Vector2;

	function rotateAround( center : Vector2, angle : Float ) : Vector2;

	function random() : Vector2;

	@:arrayAccess function get( index : Int ) : Float;
	@:arrayAccess function set( index : Int, value : Float ) : Float;

	function iterator() : Iterator<Float>;

	inline function get_width() : Float {

		return this.x;

	}

	inline function set_width( value : Float ) : Float {

		return this.x = value;

	}

	inline function get_height() : Float {

		return this.y;

	}

	inline function set_height( value : Float ) : Float {

		return this.y = value;

	}

}