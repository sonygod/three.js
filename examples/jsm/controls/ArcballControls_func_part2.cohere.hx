function onSinglePanEnd():Void {
	if (_state == STATE.ROTATE) {
		if (!enableRotate) {
			return;
		}
		if (enableAnimations) {
			var deltaTime = (Date.now() - _timeCurrent);
			if (deltaTime < 120) {
				var w = Math.abs((_wPrev + _wCurr) / 2);
				var self = this;
				_animationId = window.requestAnimationFrame(function(t) {
					self.updateTbState(STATE.ANIMATION_ROTATE, true);
					var rotationAxis = self.calculateRotationAxis(_cursorPosPrev, _cursorPosCurr);
					self.onRotationAnim(t, rotationAxis, Math.min(w, wMax));
				});
			} else {
				updateTbState(STATE.IDLE, false);
				activateGizmos(false);
				dispatchEvent(_changeEvent);
			}
		} else {
			updateTbState(STATE.IDLE, false);
			activateGizmos(false);
			dispatchEvent(_changeEvent);
		}
	} else if (_state == STATE.PAN || _state == STATE.IDLE) {
		updateTbState(STATE.IDLE, false);
		if (enableGrid) {
			disposeGrid();
		}
		activateGizmos(false);
		dispatchEvent(_changeEvent);
	}
	dispatchEvent(_endEvent);
}

function onDoubleTap(event:MouseEvent):Void {
	if (enabled && enablePan && scene != null) {
		dispatchEvent(_startEvent);
		setCenter(event.clientX, event.clientY);
		var hitP = unprojectOnObj(getCursorNDC(_center.x, _center.y, domElement), camera);
		if (hitP != null && enableAnimations) {
			var self = this;
			if (_animationId != -1) {
				window.cancelAnimationFrame(_animationId);
			}
			_timeStart = -1;
			_animationId = window.requestAnimationFrame(function(t) {
				self.updateTbState(STATE.ANIMATION_FOCUS, true);
				self.onFocusAnim(t, hitP, _cameraMatrixState, _gizmoMatrixState);
			});
		} else if (hitP != null && !enableAnimations) {
			updateTbState(STATE.FOCUS, true);
			focus(hitP, scaleFactor);
			updateTbState(STATE.IDLE, false);
			dispatchEvent(_changeEvent);
		}
		dispatchEvent(_endEvent);
	}
}

function onDoublePanStart():Void {
	if (enabled && enablePan) {
		dispatchEvent(_startEvent);
		updateTbState(STATE.PAN, true);
		setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2, (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
		_startCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement, true));
		_currentCursorPosition.copy(_startCursorPosition);
		activateGizmos(false);
	}
}

function onDoublePanMove():Void {
	if (enabled && enablePan) {
		setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2, (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
		if (_state != STATE.PAN) {
			updateTbState(STATE.PAN, true);
			_startCursorPosition.copy(_currentCursorPosition);
		}
		_currentCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement, true));
		applyTransformMatrix(pan(_startCursorPosition, _currentCursorPosition, true));
		dispatchEvent(_changeEvent);
	}
}

function onDoublePanEnd():Void {
	updateTbState(STATE.IDLE, false);
	dispatchEvent(_endEvent);
}

function onRotateStart():Void {
	if (enabled && enableRotate) {
		dispatchEvent(_startEvent);
		updateTbState(STATE.ZROTATE, true);
		_startFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);
		_currentFingerRotation = _startFingerRotation;
		camera.getWorldDirection(_rotationAxis); //rotation axis
		if (!enablePan && !enableZoom) {
			activateGizmos(true);
		}
	}
}

function onRotateMove():Void {
	if (enabled && enableRotate) {
		setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2, (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
		var rotationPoint:Vector3;
		if (_state != STATE.ZROTATE) {
			updateTbState(STATE.ZROTATE, true);
			_startFingerRotation = _currentFingerRotation;
		}
		_currentFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);
		if (!enablePan) {
			rotationPoint = new Vector3().setFromMatrixPosition(_gizmoMatrixState);
		} else {
			_v3_2.setFromMatrixPosition(_gizmoMatrixState);
			rotationPoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement).applyQuaternion(camera.quaternion).multiplyScalar(1 / camera.zoom).add(_v3_2);
		}
		var amount = MathUtils.DEG2RAD * (_startFingerRotation - _currentFingerRotation);
		applyTransformMatrix(zRotate(rotationPoint, amount));
		dispatchEvent(_changeEvent);
	}
}

function onRotateEnd():Void {
	updateTbState(STATE.IDLE, false);
	activateGizmos(false);
	dispatchEvent(_endEvent);
}

function onPinchStart():Void {
	if (enabled && enableZoom) {
		dispatchEvent(_startEvent);
		updateTbState(STATE.SCALE, true);
		_startFingerDistance = calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]);
		_currentFingerDistance = _startFingerDistance;
		activateGizmos(false);
	}
}

function onPinchMove():Void {
	if (enabled && enableZoom) {
		setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2, (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
		const minDistance = 12; //minimum distance between fingers (in css pixels)
		if (_state != STATE.SCALE) {
			_startFingerDistance = _currentFingerDistance;
			updateTbState(STATE.SCALE, true);
		}
		_currentFingerDistance = Math.max(calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]), minDistance * _devPxRatio);
		var amount = _currentFingerDistance / _startFingerDistance;
		var scalePoint:Vector3;
		if (!enablePan) {
			scalePoint = _gizmos.position;
		} else {
			if (camera.isOrthographicCamera) {
				scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement)
					.applyQuaternion(camera.quaternion)
					.multiplyScalar(1 / camera.zoom)
					.add(_gizmos.position);
			} else if (camera.isPerspectiveCamera) {
				scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement)
					.applyQuaternion(camera.quaternion)
					.add(_gizmos.position);
			}
		}
		applyTransformMatrix(scale(amount, scalePoint));
		dispatchEvent(_changeEvent);
	}
}

function onPinchEnd():Void {
	updateTbState(STATE.IDLE, false);
	dispatchEvent(_endEvent);
}

function onTriplePanStart():Void {
	if (enabled && enableZoom) {
		dispatchEvent(_startEvent);
		updateTbState(STATE.SCALE, true);
		let clientX = 0;
		let clientY = 0;
		const nFingers = _touchCurrent.length;
		for (let i = 0; i < nFingers; i++) {
			clientX += _touchCurrent[i].clientX;
			clientY += _touchCurrent[i].clientY;
		}
		setCenter(clientX / nFingers, clientY / nFingers);
		_startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
		_currentCursorPosition.copy(_startCursorPosition);
	}
}

function onTriplePanMove():Void {
	if (enabled && enableZoom) {
		let clientX = 0;
		let clientY = 0;
		const nFingers = _touchCurrent.length;
		for (let i = 0; i < nFingers; i++) {
			clientX += _touchCurrent[i].clientX;
			clientY += _touchCurrent[i].clientY;
		}
		setCenter(clientX / nFingers, clientY / nFingers);
		const screenNotches = 8; //how many wheel notches corresponds to a full screen pan
		_currentCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
		const movement = _currentCursorPosition.y - _startCursorPosition.y;
		let size = 1;
		if (movement < 0) {
			size = 1 / Math.pow(scaleFactor, -movement * screenNotches);
		} else if (movement > 0) {
			size = Math.pow(scaleFactor, movement * screenNotches);
		}
		_v3_1.setFromMatrixPosition(_cameraMatrixState);
		const x = _v3_1.distanceTo(_gizmos.position);
		let xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed
		//check min and max distance
		xNew = MathUtils.clamp(xNew, minDistance, maxDistance);
		const y = x * Math.tan(MathUtils.DEG2RAD * _fovState * 0.5);
		//calculate new fov
		let newFov = MathUtils.RAD2DEG * (Math.atan(y / xNew) * 2);
		//check min and max fov
		newFov = MathUtils.clamp(newFov, minFov, maxFov);
		const newDistance = y / Math.tan(MathUtils.DEG2RAD * (newFov / 2));
		size = x / newDistance;
		_v3_2.setFromMatrixPosition(_gizmoMatrixState);
		setFov(newFov);
		applyTransformMatrix(scale(size, _v3_2, false));
		//adjusting distance
		_offset.copy(_gizmos.position).sub(camera.position).normalize().multiplyScalar(newDistance / x);
		_m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
		dispatchEvent(_changeEvent);
	}
}

function onTriplePanEnd():Void {
	updateTbState(STATE.IDLE, false);
	dispatchEvent(_endEvent);
	//dispatchEvent(_changeEvent);
}

function setCenter(clientX:Int, clientY:Int):Void {
	_center.x = clientX;
	_center.y = clientY;
}

function initializeMouseActions():Void {
	setMouseAction('PAN', 0, 'CTRL');
	setMouseAction('PAN', 2);
	setMouseAction('ROTATE', 0);
	setMouseAction('ZOOM', 'WHEEL');
	setMouseAction('ZOOM', 1);
	setMouseAction('FOV', 'WHEEL', 'SHIFT');
	setMouseAction('FOV', 1, 'SHIFT');
}

function compareMouseAction(action1:MouseAction, action2:MouseAction):Bool {
	if (action1.operation == action2.operation) {
		if (action1.mouse == action2.mouse && action1.key == action2.key) {
			return true;
		} else {
			return false;
		}
	} else {
		return false;
	}
}