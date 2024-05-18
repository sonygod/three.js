import haxe.math.Vector2;
import haxe.math.Vector3;
import haxe.math.Matrix4;
import haxe.math.Quaternion;
import haxe.math.Ray;
import haxe.math.Box3;
import haxe.math.Sphere;
import haxe.math.MathUtils;
import haxe.math.Euler;
import openfl.events.EventDispatcher;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.Lib;

class ArcballControls extends EventDispatcher {

	public var camera:Camera;
	public var domElement:Sprite;
	public var scene:Sprite;
	public var target:Vector3 = new Vector3();
	public var _currentTarget:Vector3 = new Vector3();
	public var radiusFactor:Float = 0.67;

	public var _mouseActions:Array<Dynamic>;
	public var _mouseOp:Dynamic;

	public var _v2_1:Vector2;
	public var _v3_1:Vector3;
	public var _v3_2:Vector3;

	public var _m4_1:Matrix4;
	public var _m4_2:Matrix4;

	public var _quat:Quaternion;

	public var _translationMatrix:Matrix4;
	public var _rotationMatrix:Matrix4;
	public var _scaleMatrix:Matrix4;

	public var _rotationAxis:Vector3;

	public var _cameraMatrixState:Matrix4;
	public var _cameraProjectionState:Matrix4;

	public var _fovState:Float;
	public var _upState:Vector3;
	public var _zoomState:Float;
	public var _nearPos:Float;
	public var _farPos:Float;

	public var _gizmoMatrixState:Matrix4;

	public var _initialNear:Float;
	public var _initialFar:Float;
	public var _cameraMatrixState0:Matrix4;
	public var _gizmoMatrixState0:Matrix4;

	public var _button:Int;
	public var _touchStart:Array<Dynamic>;
	public var _touchCurrent:Array<Dynamic>;
	public var _input:Int;

	//... (rest of the class implementation)

}