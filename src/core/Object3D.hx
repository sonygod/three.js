import Quaternion;
import Vector3;
import Matrix4;
import EventDispatcher;
import Euler;
import Layers;
import Matrix3;
import MathUtils;

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
		this.isObject3D = true;
		this.id = _object3DId++;
		this.uuid = MathUtils.generateUUID();
		this.name = '';
		this.type = 'Object3D';
		this.parent = null;
		this.children = [];
		this.up = Object3D.DEFAULT_UP.clone();
		this.position = new Vector3();
		this.rotation = new Euler();
		this.quaternion = new Quaternion();
		this.scale = new Vector3(1, 1, 1);
		this.modelViewMatrix = new Matrix4();
		this.normalMatrix = new Matrix3();
		this.matrix = new Matrix4();
		this.matrixWorld = new Matrix4();
		this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
		this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
		this.matrixWorldNeedsUpdate = false;
		this.layers = new Layers();
		this.visible = true;
		this.castShadow = false;
		this.receiveShadow = false;
		this.frustumCulled = true;
		this.renderOrder = 0;
		this.animations = [];
		this.userData = {};

		this.rotation._onChange(onRotationChange);
		this.quaternion._onChange(onQuaternionChange);

		Object.defineProperties(this, {
			"position": {
				get: function () return this._position;
				set: function (value:Vector3) {
					this._position.copy(value);
					this.quaternion.setFromEuler(this.rotation, false);
				}
			},
			"rotation": {
				get: function () return this._rotation;
				set: function (value:Euler) {
					this._rotation.copy(value);
					this.quaternion.setFromEuler(this.rotation, false);
				}
			},
			"quaternion": {
				get: function () return this._quaternion;
				set: function (value:Quaternion) {
					this._quaternion.copy(value);
					this.rotation.setFromQuaternion(this.quaternion, undefined, false);
				}
			},
			"scale": {
				get: function () return this._scale;
				set: function (value:Vector3) {
					this._scale.copy(value);
				}
			}
		});
	}

	// Add the rest of the methods here...

}

Object3D.DEFAULT_UP = new Vector3(0, 1, 0);
Object3D.DEFAULT_MATRIX_AUTO_UPDATE = true;
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;