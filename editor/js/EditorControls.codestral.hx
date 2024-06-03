import three.THREE;

class EditorControls extends THREE.EventDispatcher {

	public var enabled:Bool;
	public var center:THREE.Vector3;
	public var panSpeed:Float;
	public var zoomSpeed:Float;
	public var rotationSpeed:Float;

	private var vector:THREE.Vector3;
	private var delta:THREE.Vector3;
	private var box:THREE.Box3;
	private var normalMatrix:THREE.Matrix3;
	private var pointer:THREE.Vector2;
	private var pointerOld:THREE.Vector2;
	private var spherical:THREE.Spherical;
	private var sphere:THREE.Sphere;
	private var pointers:Array<Int>;
	private var pointerPositions:haxe.ds.StringMap;
	private var changeEvent:Dynamic;
	private var domElement:Dynamic;
	private var object:Dynamic;

	public function new(object:Dynamic, domElement:Dynamic) {
		super();

		this.enabled = true;
		this.center = new THREE.Vector3();
		this.panSpeed = 0.002;
		this.zoomSpeed = 0.1;
		this.rotationSpeed = 0.005;

		this.vector = new THREE.Vector3();
		this.delta = new THREE.Vector3();
		this.box = new THREE.Box3();
		this.normalMatrix = new THREE.Matrix3();
		this.pointer = new THREE.Vector2();
		this.pointerOld = new THREE.Vector2();
		this.spherical = new THREE.Spherical();
		this.sphere = new THREE.Sphere();
		this.pointers = [];
		this.pointerPositions = new haxe.ds.StringMap();
		this.changeEvent = { type: 'change' };
		this.domElement = domElement;
		this.object = object;

		this.domElement.addEventListener('contextmenu', $bind(this, contextmenu));
		this.domElement.addEventListener('dblclick', $bind(this, onMouseUp));
		this.domElement.addEventListener('wheel', $bind(this, onMouseWheel), { passive: false });
		this.domElement.addEventListener('pointerdown', $bind(this, onPointerDown));
	}

	public function focus(target:Dynamic) {
		var distance:Float;

		this.box.setFromObject(target);

		if (this.box.isEmpty() === false) {
			this.box.getCenter(this.center);
			distance = this.box.getBoundingSphere(this.sphere).radius;
		} else {
			this.center.setFromMatrixPosition(target.matrixWorld);
			distance = 0.1;
		}

		this.delta.set(0, 0, 1);
		this.delta.applyQuaternion(this.object.quaternion);
		this.delta.multiplyScalar(distance * 4);

		this.object.position.copy(this.center).add(this.delta);

		this.dispatchEvent(this.changeEvent);
	}

	// The rest of the methods...

}