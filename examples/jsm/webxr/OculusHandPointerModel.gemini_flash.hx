import three.Object3D;
import three.Vector3;
import three.Matrix4;
import three.Quaternion;
import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Raycaster;
import three.SphereGeometry;
import three.EventDispatcher;

class OculusHandPointerModel extends Object3D {
	private hand:EventDispatcher;
	private controller:Object3D;
	private xrInputSource:Dynamic;
	private pointerGeometry:BufferGeometry;
	private pointerMesh:Mesh;
	private pointerObject:Object3D;
	private pinched:Bool;
	private attached:Bool;
	private cursorObject:Mesh;
	private raycaster:Raycaster;

	public function new(hand:EventDispatcher, controller:Object3D) {
		super();
		this.hand = hand;
		this.controller = controller;
		this.pinched = false;
		this.attached = false;
		this.raycaster = new Raycaster();

		hand.addEventListener('connected', this._onConnected);
		hand.addEventListener('disconnected', this._onDisconnected);
	}

	private function _onConnected(event:Dynamic):Void {
		if (event.data.hand != null) {
			this.visible = true;
			this.xrInputSource = event.data;
			this.createPointer();
		}
	}

	private function _onDisconnected():Void {
		this.visible = false;
		this.xrInputSource = null;
		if (this.pointerGeometry != null) this.pointerGeometry.dispose();
		if (this.pointerMesh != null && this.pointerMesh.material != null) this.pointerMesh.material.dispose();
		this.clear();
	}

	private function _drawVerticesRing(vertices:Array<Float>, baseVector:Vector3, ringIndex:Int):Void {
		var segmentVector = baseVector.clone();
		for (i in 0...POINTER_SEGMENTS) {
			segmentVector.applyAxisAngle(ZAXIS, (Math.PI * 2) / POINTER_SEGMENTS);
			var vid = ringIndex * POINTER_SEGMENTS + i;
			vertices[3 * vid] = segmentVector.x;
			vertices[3 * vid + 1] = segmentVector.y;
			vertices[3 * vid + 2] = segmentVector.z;
		}
	}

	private function _updatePointerVertices(rearRadius:Float):Void {
		var vertices = this.pointerGeometry.attributes.position.array;

		// first ring for front face
		var frontFaceBase = new Vector3(POINTER_FRONT_RADIUS, 0, -1 * (POINTER_LENGTH - rearRadius));
		this._drawVerticesRing(vertices, frontFaceBase, 0);

		// rings for rear hemisphere
		var rearBase = new Vector3(Math.sin((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius, Math.cos((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius, 0);
		for (i in 0...POINTER_RINGS) {
			this._drawVerticesRing(vertices, rearBase, i + 1);
			rearBase.applyAxisAngle(YAXIS, (Math.PI * POINTER_HEMISPHERE_ANGLE) / 180 / (POINTER_RINGS * -2));
		}

		// front and rear face center vertices
		var frontCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS);
		var rearCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
		var frontCenter = new Vector3(0, 0, -1 * (POINTER_LENGTH - rearRadius));
		vertices[frontCenterIndex * 3] = frontCenter.x;
		vertices[frontCenterIndex * 3 + 1] = frontCenter.y;
		vertices[frontCenterIndex * 3 + 2] = frontCenter.z;
		var rearCenter = new Vector3(0, 0, rearRadius);
		vertices[rearCenterIndex * 3] = rearCenter.x;
		vertices[rearCenterIndex * 3 + 1] = rearCenter.y;
		vertices[rearCenterIndex * 3 + 2] = rearCenter.z;

		this.pointerGeometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
	}

	private function createPointer():Void {
		var vertices = new Array<Float>((POINTER_RINGS + 1) * POINTER_SEGMENTS + 2 * 3).fill(0);
		var indices = new Array<Int>();

		this.pointerGeometry = new BufferGeometry();
		this.pointerGeometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));

		this._updatePointerVertices(POINTER_REAR_RADIUS);

		// construct faces to connect rings
		for (i in 0...POINTER_RINGS) {
			for (j in 0...POINTER_SEGMENTS - 1) {
				indices.push(i * POINTER_SEGMENTS + j, i * POINTER_SEGMENTS + j + 1, (i + 1) * POINTER_SEGMENTS + j);
				indices.push(i * POINTER_SEGMENTS + j + 1, (i + 1) * POINTER_SEGMENTS + j + 1, (i + 1) * POINTER_SEGMENTS + j);
			}

			indices.push((i + 1) * POINTER_SEGMENTS - 1, i * POINTER_SEGMENTS, (i + 2) * POINTER_SEGMENTS - 1);
			indices.push(i * POINTER_SEGMENTS, (i + 1) * POINTER_SEGMENTS, (i + 2) * POINTER_SEGMENTS - 1);
		}

		// construct front and rear face
		var frontCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS);
		var rearCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;

		for (i in 0...POINTER_SEGMENTS - 1) {
			indices.push(frontCenterIndex, i + 1, i);
			indices.push(rearCenterIndex, i + POINTER_SEGMENTS * POINTER_RINGS, i + POINTER_SEGMENTS * POINTER_RINGS + 1);
		}

		indices.push(frontCenterIndex, 0, POINTER_SEGMENTS - 1);
		indices.push(rearCenterIndex, POINTER_SEGMENTS * (POINTER_RINGS + 1) - 1, POINTER_SEGMENTS * POINTER_RINGS);

		var material = new MeshBasicMaterial();
		material.transparent = true;
		material.opacity = POINTER_OPACITY_MIN;

		this.pointerGeometry.setIndex(indices);

		this.pointerMesh = new Mesh(this.pointerGeometry, material);
		this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
		this.pointerObject = new Object3D();
		this.pointerObject.add(this.pointerMesh);

		// create cursor
		var cursorGeometry = new SphereGeometry(CURSOR_RADIUS, 10, 10);
		var cursorMaterial = new MeshBasicMaterial();
		cursorMaterial.transparent = true;
		cursorMaterial.opacity = POINTER_OPACITY_MIN;

		this.cursorObject = new Mesh(cursorGeometry, cursorMaterial);
		this.pointerObject.add(this.cursorObject);

		this.add(this.pointerObject);
	}

	private function _updateRaycaster():Void {
		if (this.raycaster != null) {
			var pointerMatrix = this.pointerObject.matrixWorld;
			var tempMatrix = new Matrix4();
			tempMatrix.identity().extractRotation(pointerMatrix);
			this.raycaster.ray.origin.setFromMatrixPosition(pointerMatrix);
			this.raycaster.ray.direction.set(0, 0, -1).applyMatrix4(tempMatrix);
		}
	}

	private function _updatePointer():Void {
		this.pointerObject.visible = this.controller.visible;
		var indexTip = this.hand.joints['index-finger-tip'];
		var thumbTip = this.hand.joints['thumb-tip'];
		var distance = indexTip.position.distanceTo(thumbTip.position);
		var position = indexTip.position.clone().add(thumbTip.position).multiplyScalar(0.5);
		this.pointerObject.position.copy(position);
		this.pointerObject.quaternion.copy(this.controller.quaternion);

		this.pinched = distance <= PINCH_THRESHOLD;

		var pinchScale = (distance - PINCH_MIN) / (PINCH_MAX - PINCH_MIN);
		var focusScale = (distance - PINCH_MIN) / (PINCH_THRESHOLD - PINCH_MIN);
		if (pinchScale > 1) {
			this._updatePointerVertices(POINTER_REAR_RADIUS);
			this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
			this.pointerMesh.material.opacity = POINTER_OPACITY_MIN;
		} else if (pinchScale > 0) {
			var rearRadius = (POINTER_REAR_RADIUS - POINTER_REAR_RADIUS_MIN) * pinchScale + POINTER_REAR_RADIUS_MIN;
			this._updatePointerVertices(rearRadius);
			if (focusScale < 1) {
				this.pointerMesh.position.set(0, 0, -1 * rearRadius - (1 - focusScale) * POINTER_ADVANCE_MAX);
				this.pointerMesh.material.opacity = POINTER_OPACITY_MIN + (1 - focusScale) * (POINTER_OPACITY_MAX - POINTER_OPACITY_MIN);
			} else {
				this.pointerMesh.position.set(0, 0, -1 * rearRadius);
				this.pointerMesh.material.opacity = POINTER_OPACITY_MIN;
			}
		} else {
			this._updatePointerVertices(POINTER_REAR_RADIUS_MIN);
			this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS_MIN - POINTER_ADVANCE_MAX);
			this.pointerMesh.material.opacity = POINTER_OPACITY_MAX;
		}

		this.cursorObject.material.opacity = this.pointerMesh.material.opacity;
	}

	override function updateMatrixWorld(force:Bool) {
		super.updateMatrixWorld(force);
		if (this.pointerGeometry != null) {
			this._updatePointer();
			this._updateRaycaster();
		}
	}

	public function isPinched():Bool {
		return this.pinched;
	}

	public function setAttached(attached:Bool):Void {
		this.attached = attached;
	}

	public function isAttached():Bool {
		return this.attached;
	}

	public function intersectObject(object:Object3D, recursive:Bool = true):Array<Dynamic> {
		if (this.raycaster != null) {
			return this.raycaster.intersectObject(object, recursive);
		}
		return [];
	}

	public function intersectObjects(objects:Array<Object3D>, recursive:Bool = true):Array<Dynamic> {
		if (this.raycaster != null) {
			return this.raycaster.intersectObjects(objects, recursive);
		}
		return [];
	}

	public function checkIntersections(objects:Array<Object3D>, recursive:Bool = false):Void {
		if (this.raycaster != null && !this.attached) {
			var intersections = this.raycaster.intersectObjects(objects, recursive);
			var direction = new Vector3(0, 0, -1);
			if (intersections.length > 0) {
				var intersection = intersections[0];
				var distance = intersection.distance;
				this.cursorObject.position.copy(direction.multiplyScalar(distance));
			} else {
				this.cursorObject.position.copy(direction.multiplyScalar(CURSOR_MAX_DISTANCE));
			}
		}
	}

	public function setCursor(distance:Float):Void {
		var direction = new Vector3(0, 0, -1);
		if (this.raycaster != null && !this.attached) {
			this.cursorObject.position.copy(direction.multiplyScalar(distance));
		}
	}

	public function dispose():Void {
		this._onDisconnected();
		this.hand.removeEventListener('connected', this._onConnected);
		this.hand.removeEventListener('disconnected', this._onDisconnected);
	}

	private static inline var PINCH_MAX:Float = 0.05;
	private static inline var PINCH_THRESHOLD:Float = 0.02;
	private static inline var PINCH_MIN:Float = 0.01;
	private static inline var POINTER_ADVANCE_MAX:Float = 0.02;
	private static inline var POINTER_OPACITY_MAX:Float = 1;
	private static inline var POINTER_OPACITY_MIN:Float = 0.4;
	private static inline var POINTER_FRONT_RADIUS:Float = 0.002;
	private static inline var POINTER_REAR_RADIUS:Float = 0.01;
	private static inline var POINTER_REAR_RADIUS_MIN:Float = 0.003;
	private static inline var POINTER_LENGTH:Float = 0.035;
	private static inline var POINTER_SEGMENTS:Int = 16;
	private static inline var POINTER_RINGS:Int = 12;
	private static inline var POINTER_HEMISPHERE_ANGLE:Int = 110;
	private static inline var YAXIS:Vector3 = new Vector3(0, 1, 0);
	private static inline var ZAXIS:Vector3 = new Vector3(0, 0, 1);
	private static inline var CURSOR_RADIUS:Float = 0.02;
	private static inline var CURSOR_MAX_DISTANCE:Float = 1.5;
}