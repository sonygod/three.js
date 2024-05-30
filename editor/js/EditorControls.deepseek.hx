import three.THREE;

class EditorControls extends THREE.EventDispatcher {

	public var enabled:Bool;
	public var center:THREE.Vector3;
	public var panSpeed:Float;
	public var zoomSpeed:Float;
	public var rotationSpeed:Float;

	private var scope:EditorControls;
	private var vector:THREE.Vector3;
	private var delta:THREE.Vector3;
	private var box:THREE.Box3;

	private var STATE:{ROTATE:Int, ZOOM:Int, PAN:Int, NONE:Int};
	private var state:Int;

	private var center:THREE.Vector3;
	private var normalMatrix:THREE.Matrix3;
	private var pointer:THREE.Vector2;
	private var pointerOld:THREE.Vector2;
	private var spherical:THREE.Spherical;
	private var sphere:THREE.Sphere;

	private var pointers:Array<Int>;
	private var pointerPositions:Map<Int, THREE.Vector2>;

	private var changeEvent:{type:String};

	public function new(object:Dynamic, domElement:Dynamic) {

		super();

		// API

		this.enabled = true;
		this.center = new THREE.Vector3();
		this.panSpeed = 0.002;
		this.zoomSpeed = 0.1;
		this.rotationSpeed = 0.005;

		// internals

		scope = this;
		vector = new THREE.Vector3();
		delta = new THREE.Vector3();
		box = new THREE.Box3();

		STATE = {ROTATE: 0, ZOOM: 1, PAN: 2, NONE: -1};
		state = STATE.NONE;

		center = this.center;
		normalMatrix = new THREE.Matrix3();
		pointer = new THREE.Vector2();
		pointerOld = new THREE.Vector2();
		spherical = new THREE.Spherical();
		sphere = new THREE.Sphere();

		pointers = [];
		pointerPositions = {};

		// events

		changeEvent = {type: 'change'};

		this.focus = function (target:Dynamic) {

			var distance:Float;

			box.setFromObject(target);

			if (box.isEmpty() === false) {

				box.getCenter(center);
				distance = box.getBoundingSphere(sphere).radius;

			} else {

				// Focusing on an Group, AmbientLight, etc

				center.setFromMatrixPosition(target.matrixWorld);
				distance = 0.1;

			}

			delta.set(0, 0, 1);
			delta.applyQuaternion(object.quaternion);
			delta.multiplyScalar(distance * 4);

			object.position.copy(center).add(delta);

			scope.dispatchEvent(changeEvent);

		};

		this.pan = function (delta:THREE.Vector3) {

			var distance:Float = object.position.distanceTo(center);

			delta.multiplyScalar(distance * scope.panSpeed);
			delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

			object.position.add(delta);
			center.add(delta);

			scope.dispatchEvent(changeEvent);

		};

		this.zoom = function (delta:THREE.Vector3) {

			var distance:Float = object.position.distanceTo(center);

			delta.multiplyScalar(distance * scope.zoomSpeed);

			if (delta.length() > distance) return;

			delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

			object.position.add(delta);

			scope.dispatchEvent(changeEvent);

		};

		this.rotate = function (delta:THREE.Vector3) {

			vector.copy(object.position).sub(center);

			spherical.setFromVector3(vector);

			spherical.theta += delta.x * scope.rotationSpeed;
			spherical.phi += delta.y * scope.rotationSpeed;

			spherical.makeSafe();

			vector.setFromSpherical(spherical);

			object.position.copy(center).add(vector);

			object.lookAt(center);

			scope.dispatchEvent(changeEvent);

		};

		//

		function onPointerDown(event:Dynamic) {

			if (scope.enabled === false) return;

			if (pointers.length === 0) {

				domElement.setPointerCapture(event.pointerId);

				domElement.ownerDocument.addEventListener('pointermove', onPointerMove);
				domElement.ownerDocument.addEventListener('pointerup', onPointerUp);

			}

			//

			if (isTrackingPointer(event)) return;

			//

			addPointer(event);

			if (event.pointerType === 'touch') {

				onTouchStart(event);

			} else {

				onMouseDown(event);

			}

		}

		function onPointerMove(event:Dynamic) {

			if (scope.enabled === false) return;

			if (event.pointerType === 'touch') {

				onTouchMove(event);

			} else {

				onMouseMove(event);

			}

		}

		function onPointerUp(event:Dynamic) {

			removePointer(event);

			switch (pointers.length) {

				case 0:

					domElement.releasePointerCapture(event.pointerId);

					domElement.ownerDocument.removeEventListener('pointermove', onPointerMove);
					domElement.ownerDocument.removeEventListener('pointerup', onPointerUp);

					break;

				case 1:

					var pointerId:Int = pointers[0];
					var position:THREE.Vector2 = pointerPositions[pointerId];

					// minimal placeholder event - allows state correction on pointer-up
					onTouchStart({pointerId: pointerId, pageX: position.x, pageY: position.y});

					break;

			}

		}

		// mouse

		function onMouseDown(event:Dynamic) {

			if (event.button === 0) {

				state = STATE.ROTATE;

			} else if (event.button === 1) {

				state = STATE.ZOOM;

			} else if (event.button === 2) {

				state = STATE.PAN;

			}

			pointerOld.set(event.clientX, event.clientY);

		}

		function onMouseMove(event:Dynamic) {

			pointer.set(event.clientX, event.clientY);

			var movementX:Float = pointer.x - pointerOld.x;
			var movementY:Float = pointer.y - pointerOld.y;

			if (state === STATE.ROTATE) {

				scope.rotate(delta.set(-movementX, -movementY, 0));

			} else if (state === STATE.ZOOM) {

				scope.zoom(delta.set(0, 0, movementY));

			} else if (state === STATE.PAN) {

				scope.pan(delta.set(-movementX, movementY, 0));

			}

			pointerOld.set(event.clientX, event.clientY);

		}

		function onMouseUp() {

			state = STATE.NONE;

		}

		function onMouseWheel(event:Dynamic) {

			if (scope.enabled === false) return;

			event.preventDefault();

			// Normalize deltaY due to https://bugzilla.mozilla.org/show_bug.cgi?id=1392460
			scope.zoom(delta.set(0, 0, event.deltaY > 0 ? 1 : -1));

		}

		function contextmenu(event:Dynamic) {

			event.preventDefault();

		}

		this.dispose = function () {

			domElement.removeEventListener('contextmenu', contextmenu);
			domElement.removeEventListener('dblclick', onMouseUp);
			domElement.removeEventListener('wheel', onMouseWheel);

			domElement.removeEventListener('pointerdown', onPointerDown);

		};

		domElement.addEventListener('contextmenu', contextmenu);
		domElement.addEventListener('dblclick', onMouseUp);
		domElement.addEventListener('wheel', onMouseWheel, {passive: false});

		domElement.addEventListener('pointerdown', onPointerDown);

		// touch

		var touches:Array<THREE.Vector3> = [new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3()];
		var prevTouches:Array<THREE.Vector3> = [new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3()];

		var prevDistance:Float = null;

		function onTouchStart(event:Dynamic) {

			trackPointer(event);

			switch (pointers.length) {

				case 1:
					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					break;

				case 2:

					var position:THREE.Vector2 = getSecondPointerPosition(event);

					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(position.x, position.y, 0).divideScalar(window.devicePixelRatio);
					prevDistance = touches[0].distanceTo(touches[1]);
					break;

			}

			prevTouches[0].copy(touches[0]);
			prevTouches[1].copy(touches[1]);

		}


		function onTouchMove(event:Dynamic) {

			trackPointer(event);

			function getClosest(touch:THREE.Vector3, touches:Array<THREE.Vector3>):THREE.Vector3 {

				var closest:THREE.Vector3 = touches[0];

				for (touch2 in touches) {

					if (closest.distanceTo(touch) > touch2.distanceTo(touch)) closest = touch2;

				}

				return closest;

			}

			switch (pointers.length) {

				case 1:
					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					scope.rotate(touches[0].sub(getClosest(touches[0], prevTouches)).multiplyScalar(-1));
					break;

				case 2:

					var position:THREE.Vector2 = getSecondPointerPosition(event);

					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(position.x, position.y, 0).divideScalar(window.devicePixelRatio);
					var distance:Float = touches[0].distanceTo(touches[1]);
					scope.zoom(delta.set(0, 0, prevDistance - distance));
					prevDistance = distance;


					var offset0:THREE.Vector3 = touches[0].clone().sub(getClosest(touches[0], prevTouches));
					var offset1:THREE.Vector3 = touches[1].clone().sub(getClosest(touches[1], prevTouches));
					offset0.x = -offset0.x;
					offset1.x = -offset1.x;

					scope.pan(offset0.add(offset1));

					break;

			}

			prevTouches[0].copy(touches[0]);
			prevTouches[1].copy(touches[1]);

		}

		function addPointer(event:Dynamic) {

			pointers.push(event.pointerId);

		}

		function removePointer(event:Dynamic) {

			delete pointerPositions[event.pointerId];

			for (i in 0...pointers.length) {

				if (pointers[i] == event.pointerId) {

					pointers.splice(i, 1);
					return;

				}

			}

		}

		function isTrackingPointer(event:Dynamic):Bool {

			for (i in 0...pointers.length) {

				if (pointers[i] == event.pointerId) return true;

			}

			return false;

		}

		function trackPointer(event:Dynamic) {

			var position:THREE.Vector2 = pointerPositions[event.pointerId];

			if (position === undefined) {

				position = new THREE.Vector2();
				pointerPositions[event.pointerId] = position;

			}

			position.set(event.pageX, event.pageY);

		}

		function getSecondPointerPosition(event:Dynamic):THREE.Vector2 {

			var pointerId:Int = (event.pointerId == pointers[0]) ? pointers[1] : pointers[0];

			return pointerPositions[pointerId];

		}

	}

}

typedef EditorControls = three.EditorControls;