import js.html.Lib;
import three.math.Quaternion;
import three.math.Vector3;
import three.math.Matrix4;
import three.core.EventDispatcher;
import three.math.Euler;
import three.core.Layers;
import three.math.Matrix3;
import three.math.MathUtils;

var _object3DId = 0;

var _v1 = new Vector3();
var _q1 = new Quaternion();
var _m1 = new Matrix4();
var _target = new Vector3();

var _position = new Vector3();
var _scale = new Vector3();
var _quaternion = new Quaternion();

var _xAxis = new Vector3(1, 0, 0);
var _yAxis = new Vector3(0, 1, 0);
var _zAxis = new Vector3(0, 0, 1);

var _addedEvent = { type: 'added' };
var _removedEvent = { type: 'removed' };

var _childaddedEvent = { type: 'childadded', child: null };
var _childremovedEvent = { type: 'childremoved', child: null };

class Object3D extends EventDispatcher {

    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var type:String;
    public var parent:Object3D;
    public var children:Array<Object3D>;
    public var up:Vector3;
    public var position:Vector3;
    public var rotation:Euler;
    public var quaternion:Quaternion;
    public var scale:Vector3;
    public var modelViewMatrix:Matrix4;
    public var normalMatrix:Matrix3;
    public var matrix:Matrix4;
    public var matrixWorld:Matrix4;
    public var matrixAutoUpdate:Bool;
    public var matrixWorldAutoUpdate:Bool;
    public var matrixWorldNeedsUpdate:Bool;
    public var layers:Layers;
    public var visible:Bool;
    public var castShadow:Bool;
    public var receiveShadow:Bool;
    public var frustumCulled:Bool;
    public var renderOrder:Int;
    public var animations:Array<Dynamic>;
    public var userData:Dynamic;

    public function new() {
        super();

        id = _object3DId++;
        uuid = MathUtils.generateUUID();

        name = '';
        type = 'Object3D';

        parent = null;
        children = [];

        up = Object3D.DEFAULT_UP.clone();

        position = new Vector3();
        rotation = new Euler();
        quaternion = new Quaternion();
        scale = new Vector3(1, 1, 1);

        rotation._onChange(() -> {
            quaternion.setFromEuler(rotation, false);
        });

        quaternion._onChange(() -> {
            rotation.setFromQuaternion(quaternion, undefined, false);
        });

        modelViewMatrix = new Matrix4();
        normalMatrix = new Matrix3();

        matrix = new Matrix4();
        matrixWorld = new Matrix4();

        matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
        matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
        matrixWorldNeedsUpdate = false;

        layers = new Layers();
        visible = true;

        castShadow = false;
        receiveShadow = false;

        frustumCulled = true;
        renderOrder = 0;

        animations = [];

        userData = {};
    }

    // ... continue the conversion for the rest of the methods
}

Object3D.DEFAULT_UP = new Vector3(0, 1, 0);
Object3D.DEFAULT_MATRIX_AUTO_UPDATE = true;
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;