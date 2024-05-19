package three.js.editor.js;

import three.js.Lib;

class EditorControls extends three.js.EventDispatcher {
	var enabled:Bool = true;
	var center:Vector3;
	var panSpeed:Float = 0.002;
	var zoomSpeed:Float = 0.1;
	var rotationSpeed:Float = 0.005;

	var scope:EditorControls;
	var vector:Vector3;
	var delta:Vector3;
	var box:Box3;

	var STATE = {
		NONE: -1,
		ROTATE: 0,
		ZOOM: 1,
		PAN: 2
	}
	var state:Int = STATE.NONE;

	var center:Vector3;
	var normalMatrix:Matrix3;
	var pointer:Vector2;
	var pointerOld:Vector2;
	var spherical:Spherical;
	var sphere:Sphere;

	var pointers:Array<Int> = [];
	var pointerPositions:Map<Int, Vector2> = [];

	var changeEvent:Event = { type: 'change' };

	public function new(object:Object3D, domElement:js.html.Element) {
		super();

		center = new Vector3();
		normalMatrix = new Matrix3();
		pointer = new Vector2();
		pointerOld = new Vector2();
		spherical = new Spherical();
		sphere = new Sphere();
		vector = new Vector3();
		delta = new Vector3();
		box = new Box3();

		this.focus = function(target:Object3D) {
			var distance:Float;

			box.setFromObject(target);

			if (!box.isEmpty()) {
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

			dispatchEvent(changeEvent);
		};

		this.pan = function(delta:Vector3) {
			var distance:Float = object.position.distanceTo(center);

			delta.multiplyScalar(distance * panSpeed);
			delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

			object.position.add(delta);
			center.add(delta);

			dispatchEvent(changeEvent);
		};

		this.zoom = function(delta:Vector3) {
			var distance:Float = object.position.distanceTo(center);

			delta.multiplyScalar(distance * zoomSpeed);

			if (delta.length() > distance) return;

			delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

			object.position.add(delta);

			dispatchEvent(changeEvent);
		};

		this.rotate = function(delta:Vector3) {
			vector.copy(object.position).sub(center);

			spherical.setFromVector3(vector);

			spherical.theta += delta.x * rotationSpeed;
			spherical.phi += delta.y * rotationSpeed;

			spherical.makeSafe();

			vector.setFromSpherical(spherical);

			object.position.copy(center).add(vector);

			object.lookAt(center);

			dispatchEvent(changeEvent);
		};

		var onPointerDown = function(event:js.html.PointerEvent) {
			if (!enabled) return;

			if (pointers.length == 0) {
				domElement.setPointerCapture(event.pointerId);

				domElement.ownerDocument.addEventListener('pointermove', onPointerMove);
				domElement.ownerDocument.addEventListener('pointerup', onPointerUp);
			}

			if (isTrackingPointer(event)) return;

			addPointer(event);
			if (event.pointerType == 'touch') {
				onTouchStart(event);
			} else {
				onMouseDown(event);
			}
		}

		var onPointerMove = function(event:js.html.PointerEvent) {
			if (!enabled) return;

			if (event.pointerType == 'touch') {
				onTouchMove(event);
			} else {
				onMouseMove(event);
			}
		}

		var onPointerUp = function(event:js.html.PointerEvent) {
			removePointer(event);

			switch (pointers.length) {
				case 0:
					domElement.releasePointerCapture(event.pointerId);

					domElement.ownerDocument.removeEventListener('pointermove', onPointerMove);
					domElement.ownerDocument.removeEventListener('pointerup', onPointerUp);

					break;

				case 1:
					var pointerId:Int = pointers[0];
					var position:Vector2 = pointerPositions[pointerId];

					// minimal placeholder event - allows state correction on pointer-up
					onTouchStart({ pointerId: pointerId, pageX: position.x, pageY: position.y });

					break;
			}
		}

		// mouse

		var onMouseDown = function(event:js.html.MouseEvent) {
			if (event.button == 0) {
				state = STATE.ROTATE;
			} else if (event.button == 1) {
				state = STATE.ZOOM;
			} else if (event.button == 2) {
				state = STATE.PAN;
			}

			pointerOld.set(event.clientX, event.clientY);
		}

		var onMouseMove = function(event:js.html.MouseEvent) {
			pointer.set(event.clientX, event.clientY);

			var movementX:Float = pointer.x - pointerOld.x;
			var movementY:Float = pointer.y - pointerOld.y;

			if (state == STATE.ROTATE) {
				rotate(delta.set(-movementX, -movementY, 0));
			} else if (state == STATE.ZOOM) {
				zoom(delta.set(0, 0, movementY));
			} else if (state == STATE.PAN) {
				pan(delta.set(-movementX, movementY, 0));
			}

			pointerOld.set(event.clientX, event.clientY);
		}

		var onMouseUp = function() {
			state = STATE.NONE;
		}

		var onMouseWheel = function(event:js.html.WheelEvent) {
			if (!enabled) return;

			event.preventDefault();

			// Normalize deltaY due to https://bugzilla.mozilla.org/show_bug.cgi?id=1392460
			zoom(delta.set(0, 0, event.deltaY > 0 ? 1 : -1));
		}

		var contextmenu = function(event:js.html.MouseEvent) {
			event.preventDefault();
		}

		this.dispose = function() {
			domElement.removeEventListener('contextmenu', contextmenu);
			domElement.removeEventListener('dblclick', onMouseUp);
			domElement.removeEventListener('wheel', onMouseWheel);

			domElement.removeEventListener('pointerdown', onPointerDown);
		}

		domElement.addEventListener('contextmenu', contextmenu);
		domElement.addEventListener('dblclick', onMouseUp);
		domElement.addEventListener('wheel', onMouseWheel, { passive: false });

		domElement.addEventListener('pointerdown', onPointerDown);

		// touch

		var touches:Array<Vector3> = [new Vector3(), new Vector3(), new Vector3()];
		var prevTouches:Array<Vector3> = [new Vector3(), new Vector3(), new Vector3()];
		var prevDistance:Float = null;

		var onTouchStart = function(event:js.html.TouchEvent) {
			trackPointer(event);

			switch (pointers.length) {
				case 1:
					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					break;

				case 2:
					var position:Vector2 = getSecondPointerPosition(event);

					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(position.x, position.y, 0).divideScalar(window.devicePixelRatio);
					prevDistance = touches[0].distanceTo(touches[1]);
					break;
			}

			prevTouches[0].copy(touches[0]);
			prevTouches[1].copy(touches[1]);
		}

		var onTouchMove = function(event:js.html.TouchEvent) {
			trackPointer(event);

			function getClosest(touch:Vector3, touches:Array<Vector3>) {
				var closest:Vector3 = touches[0];

				for (touch2 in touches) {
					if (closest.distanceTo(touch) > touch2.distanceTo(touch)) closest = touch2;
				}

				return closest;
			}

			switch (pointers.length) {
				case 1:
					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					rotate(touches[0].sub(getClosest(touches[0], prevTouches)).multiplyScalar(-1));
					break;

				case 2:
					var position:Vector2 = getSecondPointerPosition(event);

					touches[0].set(event.pageX, event.pageY, 0).divideScalar(window.devicePixelRatio);
					touches[1].set(position.x, position.y, 0).divideScalar(window.devicePixelRatio);
					var distance:Float = touches[0].distanceTo(touches[1]);
					zoom(delta.set(0, 0, prevDistance - distance));
					prevDistance = distance;

					var offset0:Vector3 = touches[0].clone().sub(getClosest(touches[0], prevTouches));
					var offset1:Vector3 = touches[1].clone().sub(getClosest(touches[1], prevTouches));
					offset0.x = -offset0.x;
					offset1.x = -offset1.x;

					pan(offset0.add(offset1));
					break;
			}

			prevTouches[0].copy(touches[0]);
			prevTouches[1].copy(touches[1]);
		}

		var addPointer = function(event:js.html.PointerEvent) {
			pointers.push(event.pointerId);
		}

		var removePointer = function(event:js.html.PointerEvent) {
			delete pointerPositions[event.pointerId];

			for (i in 0...pointers.length) {
				if (pointers[i] == event.pointerId) {
					pointers.splice(i, 1);
					return;
				}
			}
		}

		var isTrackingPointer = function(event:js.html.PointerEvent) {
			for (i in 0...pointers.length) {
				if (pointers[i] == event.pointerId) return true;
			}

			return false;
		}

		var trackPointer = function(event:js.html.PointerEvent) {
			var position:Vector2 = pointerPositions[event.pointerId];

			if (position == null) {
				position = new Vector2();
				pointerPositions[event.pointerId] = position;
			}

			position.set(event.pageX, event.pageY);
		}

		var getSecondPointerPosition = function(event:js.html.PointerEvent) {
			var pointerId:Int = (event.pointerId == pointers[0]) ? pointers[1] : pointers[0];

			return pointerPositions[pointerId];
		}
	}
}