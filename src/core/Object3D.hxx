import three.math.Quaternion;
import three.math.Vector3;
import three.math.Matrix4;
import three.core.EventDispatcher;
import three.math.Euler;
import three.core.Layers;
import three.math.Matrix3;
import three.math.MathUtils;

private static var _object3DId = 0;

private static var _v1 = new Vector3();
private static var _q1 = new Quaternion();
private static var _m1 = new Matrix4();
private static var _target = new Vector3();

private static var _position = new Vector3();
private static var _scale = new Vector3();
private static var _quaternion = new Quaternion();

private static var _xAxis = new Vector3(1, 0, 0);
private static var _yAxis = new Vector3(0, 1, 0);
private static var _zAxis = new Vector3(0, 0, 1);

private static var _addedEvent = {type: 'added'};
private static var _removedEvent = {type: 'removed'};

private static var _childaddedEvent = {type: 'childadded', child: null};
private static var _childremovedEvent = {type: 'childremoved', child: null};

class Object3D extends EventDispatcher {

    public function new() {
        super();

        this.isObject3D = true;

        this.id = _object3DId++;

        this.uuid = MathUtils.generateUUID();

        this.name = '';
        this.type = 'Object3D';

        this.parent = null;
        this.children = [];

        this.up = Object3D.DEFAULT_UP.clone();

        var position = new Vector3();
        var rotation = new Euler();
        var quaternion = new Quaternion();
        var scale = new Vector3(1, 1, 1);

        function onRotationChange() {
            quaternion.setFromEuler(rotation, false);
        }

        function onQuaternionChange() {
            rotation.setFromQuaternion(quaternion, undefined, false);
        }

        rotation._onChange(onRotationChange);
        quaternion._onChange(onQuaternionChange);

        this.position = position;
        this.rotation = rotation;
        this.quaternion = quaternion;
        this.scale = scale;

        this.modelViewMatrix = new Matrix4();
        this.normalMatrix = new Matrix3();

        this.matrix = new Matrix4();
        this.matrixWorld = new Matrix4();

        this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;

        this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
        this.matrixWorldNeedsUpdate = false;

        this.layers = new Layers();
        this.visible = true;

        this.castShadow = false;
        this.receiveShadow = false;

        this.frustumCulled = true;
        this.renderOrder = 0;

        this.animations = [];

        this.userData = {};
    }

    // ... 其他方法的实现与 JavaScript 版本相同 ...
}

Object3D.DEFAULT_UP = new Vector3(0, 1, 0);
Object3D.DEFAULT_MATRIX_AUTO_UPDATE = true;
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;