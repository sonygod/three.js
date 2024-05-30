function setMouseAction(operation:String, mouse:Int, key:Null<Int>):Bool {
	var operationInput:Array<String> = ["PAN", "ROTATE", "ZOOM", "FOV"];
	var mouseInput:Array<Dynamic> = [0, 1, 2, "WHEEL"];
	var keyInput:Array<String> = ["CTRL", "SHIFT", null];
	var state:Null<Dynamic>;

	if (!operationInput.includes(operation) || !mouseInput.includes(mouse) || !keyInput.includes(key)) {
		//invalid parameters
		return false;
	}

	if (mouse == "WHEEL") {
		if (operation != "ZOOM" && operation != "FOV") {
			//cannot associate 2D operation to 1D input
			return false;
		}
	}

	switch (operation) {
		case "PAN":
			state = STATE.PAN;
			break;
		case "ROTATE":
			state = STATE.ROTATE;
			break;
		case "ZOOM":
			state = STATE.SCALE;
			break;
		case "FOV":
			state = STATE.FOV;
			break;
	}

	var action:Dynamic = {
		operation: operation,
		mouse: mouse,
		key: key,
		state: state
	};

	for (i in 0...mouseActions.length) {
		if (mouseActions[i].mouse == action.mouse && mouseActions[i].key == action.key) {
			mouseActions[i] = action;
			return true;
		}
	}

	mouseActions.push(action);
	return true;
}

function unsetMouseAction(mouse:Int, key:Null<Int>):Bool {
	for (i in 0...mouseActions.length) {
		if (mouseActions[i].mouse == mouse && mouseActions[i].key == key) {
			mouseActions.splice(i, 1);
			return true;
		}
	}

	return false;
}

function getOpFromAction(mouse:Int, key:Int):Null<String> {
	var action:Null<Dynamic>;

	for (i in 0...mouseActions.length) {
		action = mouseActions[i];
		if (action.mouse == mouse && action.key == key) {
			return action.operation;
		}
	}

	if (key != null) {
		for (i in 0...mouseActions.length) {
			action = mouseActions[i];
			if (action.mouse == mouse && action.key == null) {
				return action.operation;
			}
		}
	}

	return null;
}

function getOpStateFromAction(mouse:Int, key:Int):Null<Dynamic> {
	var action:Null<Dynamic>;

	for (i in 0...mouseActions.length) {
		action = mouseActions[i];
		if (action.mouse == mouse && action.key == key) {
			return action.state;
		}
	}

	if (key != null) {
		for (i in 0...mouseActions.length) {
			action = mouseActions[i];
			if (action.mouse == mouse && action.key == null) {
				return action.state;
			}
		}
	}

	return null;
}

function getAngle(p1:Dynamic, p2:Dynamic):Float {
	return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX) * 180 / Math.PI;
}

function updateTouchEvent(event:Dynamic) {
	for (i in 0..._touchCurrent.length) {
		if (_touchCurrent[i].pointerId == event.pointerId) {
			_touchCurrent[i] = event;
			break;
		}
	}
}

function applyTransformMatrix(transformation:Dynamic) {
	if (transformation.camera != null) {
		_m4_1.copy(_cameraMatrixState).premultiply(transformation.camera);
		_m4_1.decompose(camera.position, camera.quaternion, camera.scale);
		camera.updateMatrix();

		//update camera up vector
		if (_state == STATE.ROTATE || _state == STATE.ZROTATE || _state == STATE.ANIMATION_ROTATE) {
			camera.up.copy(_upState).applyQuaternion(camera.quaternion);
		}
	}

	if (transformation.gizmos != null) {
		_m4_1.copy(_gizmoMatrixState).premultiply(transformation.gizmos);
		_m4_1.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
		_gizmos.updateMatrix();
	}

	if (_state == STATE.SCALE || _state == STATE.FOCUS || _state == STATE.ANIMATION_FOCUS) {
		_tbRadius = calculateTbRadius(camera);

		if (adjustNearFar) {
			var cameraDistance:Float = camera.position.distanceTo(_gizmos.position);

			var bb:Box3 = new Box3();
			bb.setFromObject(_gizmos);
			var sphere:Sphere = new Sphere();
			bb.getBoundingSphere(sphere);

			var adjustedNearPosition:Float = Math.max(_nearPos0, sphere.radius + sphere.center.length());
			var regularNearPosition:Float = cameraDistance - _initialNear;

			var minNearPos:Float = Math.min(adjustedNearPosition, regularNearPosition);
			camera.near = cameraDistance - minNearPos;

			var adjustedFarPosition:Float = Math.min(_farPos0, -sphere.radius + sphere.center.length());
			var regularFarPosition:Float = cameraDistance - _initialFar;

			var minFarPos:Float = Math.min(adjustedFarPosition, regularFarPosition);
			camera.far = cameraDistance - minFarPos;

			camera.updateProjectionMatrix();
		} else {
			var update:Bool = false;

			if (camera.near != _initialNear) {
				camera.near = _initialNear;
				update = true;
			}

			if (camera.far != _initialFar) {
				camera.far = _initialFar;
				update = true;
			}

			if (update) {
				camera.updateProjectionMatrix();
			}
		}
	}
}

function calculateAngularSpeed(p0:Float, p1:Float, t0:Float, t1:Float):Float {
	var s:Float = p1 - p0;
	var t:Float = (t1 - t0) / 1000;
	if (t == 0) {
		return 0;
	}

	return s / t;
}

function calculatePointersDistance(p0:Dynamic, p1:Dynamic):Float {
	return Math.sqrt(Math.pow(p1.clientX - p0.clientX, 2) + Math.pow(p1.clientY - p0.clientY, 2));
}

function calculateRotationAxis(vec1:Dynamic, vec2:Dynamic):Dynamic {
	_rotationMatrix.extractRotation(_cameraMatrixState);
	_quat.setFromRotationMatrix(_rotationMatrix);

	_rotationAxis.crossVectors(vec1, vec2).applyQuaternion(_quat);
	return _rotationAxis.normalize().clone();
}

function calculateTbRadius(camera:Dynamic):Float {
	var distance:Float = camera.position.distanceTo(_gizmos.position);

	if (camera.type == "PerspectiveCamera") {
		var halfFovV:Float = MathUtils.DEG2RAD * camera.fov * 0.5; //vertical fov/2 in radians
		var halfFovH:Float = Math.atan((camera.aspect) * Math.tan(halfFovV)); //horizontal fov/2 in radians
		return Math.tan(Math.min(halfFovV, halfFovH)) * distance * radiusFactor;
	} else if (camera.type == "OrthographicCamera") {
		return Math.min(camera.top, camera.right) * radiusFactor;
	}
}

function focus(point:Dynamic, size:Dynamic, amount:Float = 1) {
	//move center of camera (along with gizmos) towards point of interest
	_offset.copy(point).sub(_gizmos.position).multiplyScalar(amount);
	_translationMatrix.makeTranslation(_offset.x, _offset.y, _offset.z);

	_gizmoMatrixStateTemp.copy(_gizmoMatrixState);
	_gizmoMatrixState.premultiply(_translationMatrix);
	_gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

	_cameraMatrixStateTemp.copy(_cameraMatrixState);
	_cameraMatrixState.premultiply(_translationMatrix);
	_cameraMatrixState.decompose(camera.position, camera.quaternion, camera.scale);

	//apply zoom
	if (enableZoom) {
		applyTransformMatrix(scale(size, _gizmos.position));
	}

	_gizmoMatrixState.copy(_gizmoMatrixStateTemp);
	_cameraMatrixState.copy(_cameraMatrixStateTemp);
}

function drawGrid() {
	if (scene != null) {
		var color:Int = 0x888888;
		var multiplier:Int = 3;
		var size:Null<Float>;
		var divisions:Null<Float>;
		var maxLength:Null<Float>;
		var tick:Null<Float>;

		if (camera.isOrthographicCamera) {
			var width:Float = camera.right - camera.left;
			var height:Float = camera.bottom - camera.top;

			maxLength = Math.max(width, height);
			tick = maxLength / 20;

			size = maxLength / camera.zoom * multiplier;
			divisions = size / tick * camera.zoom;
		} else if (camera.isPerspectiveCamera) {
			var distance:Float = camera.position.distanceTo(_gizmos.position);
			var halfFovV:Float = MathUtils.DEG2RAD * camera.fov * 0.5;
			var halfFovH:Float = Math.atan((camera.aspect) * Math.tan(halfFovV));

			maxLength = Math.tan(Math.max(halfFovV, halfFovH)) * distance * 2;
			tick = maxLength / 20;

			size = maxLength * multiplier;
			divisions = size / tick;
		}

		if (_grid == null) {
			_grid = new GridHelper(size, divisions, color, color);
			_grid.position.copy(_gizmos.position);
			_gridPosition.copy(_grid.position);
			_grid.quaternion.copy(camera.quaternion);
			_grid.rotateX(Math.PI * 0.5);

			scene.add(_grid);
		}
	}
}

function dispose() {
	if (_animationId != -1) {
		window.cancelAnimationFrame(_animationId);
	}

	domElement.removeEventListener("pointerdown", _onPointerDown);
	domElement.removeEventListener("pointercancel", _onPointerCancel);
	domElement.removeEventListener("wheel", _onWheel);
	domElement.removeEventListener("contextmenu", _onContextMenu);

	window.removeEventListener("pointermove", _onPointerMove);
	window.removeEventListener("pointerup", _onPointerUp);

	window.removeEventListener("resize", _onWindowResize);

	if (scene != null) scene.remove(_gizmos);
	disposeGrid();
}

function disposeGrid() {
	if (_grid != null && scene != null) {
		scene.remove(_grid);
		_grid = null;
	}
}

function easeOutCubic(t:Float):Float {
	return 1 - Math.pow(1 - t, 3);
}

function activateGizmos(isActive:Bool) {
	var gizmoX:Dynamic = _gizmos.children[0];
	var gizmoY:Dynamic = _gizmos.children[1];
	var gizmoZ:Dynamic = _gizmos.children[2];

	if (isActive) {
		gizmoX.material.setValues({opacity: 1});
		gizmoY.material.setValues({opacity: 1});
		gizmoZ.material.setValues({opacity: 1});
	} else {
		gizmoX.material.setValues({opacity: 0.6});
		gizmoY.material.setValues({opacity: 0.6});
		gizmoZ.material.setValues({opacity: 0.6});
	}
}

function getCursorNDC(cursorX:Float, cursorY:Float, canvas:Dynamic):Dynamic {
	var canvasRect:Dynamic = canvas.getBoundingClientRect();
	_v2_1.setX(((cursorX - canvasRect.left) / canvasRect.width) * 2 - 1);
	_v2_1.setY(((canvasRect.bottom - cursorY) / canvasRect.height) * 2 - 1);
	return _v2_1.clone();
}

function getCursorPosition(cursorX:Float, cursorY:Float, canvas:Dynamic):Dynamic {
	_v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));
	_v2_1.x *= (camera.right - camera.left) * 0.5;
	_v2_1.y *= (camera.top - camera.bottom) * 0.5;
	return _v2_1.clone();
}

function setCamera(camera:Dynamic) {
	camera.lookAt(target);
	camera.updateMatrix();

	//setting state
	if (camera.type == "PerspectiveCamera") {
		_fov0 = camera.fov;
		_fovState = camera.fov;
	}

	_cameraMatrixState0.copy(camera.matrix);
	_cameraMatrixState.copy(_cameraMatrixState0);
	_cameraProjectionState.copy(camera.projectionMatrix);
	_zoom0 = camera.zoom;
	_zoomState = _zoom0;

	_initialNear = camera.near;
	_nearPos0 = camera.position.distanceTo(target) - camera.near;
	_nearPos = _initialNear;

	_initialFar = camera.far;
	_farPos0 = camera.position.distanceTo(target) - camera.far;
	_farPos = _initialFar;

	_up0.copy(camera.up);
	_upState.copy(camera.up);

	this.camera = camera;
	camera.updateProjectionMatrix();

	//making gizmos
	_tbRadius = calculateTbRadius(camera);
	makeGizmos(target, _tbRadius);
}

function setGizmosVisible(value:Bool) {
	_gizmos.visible = value;
	dispatchEvent(_changeEvent);
}