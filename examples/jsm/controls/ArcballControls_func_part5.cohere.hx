public function zRotate(point:Vector3D, angle:Float):Matrix3D {
	_rotationMatrix.makeRotationAxis(_rotationAxis, angle);
	_translationMatrix.makeTranslation(-point.x, -point.y, -point.z);

	_m4_1.makeTranslation(point.x, point.y, point.z);
	_m4_1.multiply(_rotationMatrix);
	_m4_1.multiply(_translationMatrix);

	_v3_1.setFromMatrixPosition(_gizmoMatrixState).subtract(point); //vector from rotation center to gizmos position
	_v3_2.copy(_v3_1).applyAxisAngle(_rotationAxis, angle); //apply rotation
	_v3_2.subtract(_v3_1);

	_m4_2.makeTranslation(_v3_2.x, _v3_2.y, _v3_2.z);

	setTransformationMatrices(_m4_1, _m4_2);
	return _transformation;
}

public function getRaycaster():Raycaster {
	return _raycaster;
}

public function unprojectOnObj(cursor:Vector2, camera:Camera):Vector3 {
	var raycaster = getRaycaster();
	raycaster.near = camera.near;
	raycaster.far = camera.far;
	raycaster.setFromCamera(cursor, camera);

	var intersect = raycaster.intersectObjects(scene.children, true);

	for (i in 0...intersect.length) {
		if (intersect[i].object.uuid != _gizmos.uuid && intersect[i].face != null) {
			return intersect[i].point.clone();
		}
	}

	return null;
}

public function unprojectOnTbSurface(camera:Camera, cursorX:Float, cursorY:Float, canvas:HTMLCanvasElement, tbRadius:Float):Vector3 {
	if (camera.type == 'OrthographicCamera') {
		_v2_1.copy(getCursorPosition(cursorX, cursorY, canvas));
		_v3_1.set(_v2_1.x, _v2_1.y, 0);

		var x2 = Math.pow(_v2_1.x, 2);
		var y2 = Math.pow(_v2_1.y, 2);
		var r2 = Math.pow(tbRadius, 2);

		if (x2 + y2 <= r2 * 0.5) {
			//intersection with sphere
			_v3_1.z = Math.sqrt(r2 - (x2 + y2));
		} else {
			//intersection with hyperboloid
			_v3_1.z = (r2 * 0.5) / Math.sqrt(x2 + y2);
		}

		return _v3_1;
	} else if (camera.type == 'PerspectiveCamera') {
		//unproject cursor on the near plane
		_v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));

		_v3_1.set(_v2_1.x, _v2_1.y, -1);
		_v3_1.applyMatrix4(camera.projectionMatrixInverse);

		var rayDir = _v3_1.clone().normalize(); //unprojected ray direction
		var cameraGizmoDistance = camera.position.distanceTo(_gizmos.position);
		var radius2 = Math.pow(tbRadius, 2);

		//	  camera
		//		|\
		//		| \
		//		|  \
		//	h	|	\
		//		| 	 \
		//		| 	  \
		//	_ _ | _ _ _\ _ _  near plane
		//			l

		var h = _v3_1.z;
		var l = Math.sqrt(Math.pow(_v3_1.x, 2) + Math.pow(_v3_1.y, 2));

		if (l == 0) {
			//ray aligned with camera
			rayDir.set(_v3_1.x, _v3_1.y, tbRadius);
			return rayDir;
		}

		var m = h / l;
		var q = cameraGizmoDistance;

		/*
		 * calculate intersection point between unprojected ray and trackball surface
		 *|y = m * x + q
		 *|x^2 + y^2 = r^2
		 *
		 * (m^2 + 1) * x^2 + (2 * m * q) * x + q^2 - r^2 = 0
		 */
		var a = Math.pow(m, 2) + 1;
		var b = 2 * m * q;
		var c = Math.pow(q, 2) - radius2;
		var delta = Math.pow(b, 2) - (4 * a * c);

		if (delta >= 0) {
			//intersection with sphere
			_v2_1.x = (- b - Math.sqrt(delta)) / (2 * a);
			_v2_1.y = m * _v2_1.x + q;

			var angle = MathUtils.RAD2DEG * _v2_1.angle();

			if (angle >= 45) {
				//if angle between intersection point and X' axis is >= 45°, return that point
				//otherwise, calculate intersection point with hyperboloid

				var rayLength = Math.sqrt(Math.pow(_v2_1.x, 2) + Math.pow((cameraGizmoDistance - _v2_1.y), 2));
				rayDir.multiplyScalar(rayLength);
				rayDir.z += cameraGizmoDistance;
				return rayDir;
			}
		}

		//intersection with hyperboloid
		/*
		 *|y = m * x + q
		 *|y = (1 / x) * (r^2 / 2)
		 *
		 * m * x^2 + q * x - r^2 / 2 = 0
		 */

		a = m;
		b = q;
		c = - radius2 * 0.5;
		delta = Math.pow(b, 2) - (4 * a * c);
		_v2_1.x = (- b - Math.sqrt(delta)) / (2 * a);
		_v2_1.y = m * _v2_1.x + q;

		var rayLength = Math.sqrt(Math.pow(_v2_1.x, 2) + Math.pow((cameraGizmoDistance - _v2_1.y), 2));

		rayDir.multiplyScalar(rayLength);
		rayDir.z += cameraGizmoDistance;
		return rayDir;
	}
}

public function unprojectOnTbPlane(camera:Camera, cursorX:Float, cursorY:Float, canvas:HTMLCanvasElement, initialDistance:Bool = false):Vector3 {
	if (camera.type == 'OrthographicCamera') {
		_v2_1.copy(getCursorPosition(cursorX, cursorY, canvas));
		_v3_1.set(_v2_1.x, _v2_1.y, 0);

		return _v3_1.clone();
	} else if (camera.type == 'PerspectiveCamera') {
		_v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));

		//unproject cursor on the near plane
		_v3_1.set(_v2_1.x, _v2_1.y, -1);
		_v3_1.applyMatrix4(camera.projectionMatrixInverse);

		var rayDir = _v3_1.clone().normalize(); //unprojected ray direction

		//	  camera
		//		|\
		//		| \
		//		|  \
		//	h	|	\
		//		| 	 \
		//		| 	  \
		//	_ _ | _ _ _\ _ _  near plane
		//			l

		var h = _v3_1.z;
		var l = Math.sqrt(Math.pow(_v3_1.x, 2) + Math.pow(_v3_1.y, 2));
		var cameraGizmoDistance:Float;

		if (initialDistance) {
			cameraGizmoDistance = _v3_1.setFromMatrixPosition(_cameraMatrixState0).distanceTo(_v3_2.setFromMatrixPosition(_gizmoMatrixState0));
		} else {
			cameraGizmoDistance = camera.position.distanceTo(_gizmos.position);
		}

		/*
		 * calculate intersection point between unprojected ray and the plane
		 *|y = mx + q
		 *|y = 0
		 *
		 * x = -q/m
		*/
		if (l == 0) {
			//ray aligned with camera
			rayDir.set(0, 0, 0);
			return rayDir;
		}

		var m = h / l;
		var q = cameraGizmoDistance;
		var x = - q / m;

		var rayLength = Math.sqrt(Math.pow(q, 2) + Math.pow(x, 2));
		rayDir.multiplyScalar(rayLength);
		rayDir.z = 0;
		return rayDir;
	}
}

public function updateMatrixState():Void {
	//update camera and gizmos state
	_cameraMatrixState.copy(camera.matrix);
	_gizmoMatrixState.copy(_gizmos.matrix);

	if (camera.isOrthographicCamera) {
		_cameraProjectionState.copy(camera.projectionMatrix);
		camera.updateProjectionMatrix();
		_zoomState = camera.zoom;
	} else if (camera.isPerspectiveCamera) {
		_fovState = camera.fov;
	}
}

public function updateTbState(newState:Int, updateMatrices:Bool):Void {
	_state = newState;
	if (updateMatrices) {
		updateMatrixState();
	}
}

public function update():Void {
	var EPS = 0.000001;

	if (target.equals(_currentTarget) == false) {
		_gizmos.position.copy(target); //for correct radius calculation
		_tbRadius = calculateTbRadius(camera);
		makeGizmos(target, _tbRadius);
		_currentTarget.copy(target);
	}

	//check min/max parameters
	if (camera.isOrthographicCamera) {
		//check zoom
		if (camera.zoom > maxZoom || camera.zoom < minZoom) {
			var newZoom = MathUtils.clamp(camera.zoom, minZoom, maxZoom);
			applyTransformMatrix(scale(newZoom / camera.zoom, _gizmos.position, true));
		}
	} else if (camera.isPerspectiveCamera) {
		//check distance
		var distance = camera.position.distanceTo(_gizmos.position);

		if (distance > maxDistance + EPS || distance < minDistance - EPS) {
			var newDistance = MathUtils.clamp(distance, minDistance, maxDistance);
			applyTransformMatrix(scale(newDistance / distance, _gizmos.position));
			updateMatrixState();
	 }

		//check fov
		if (camera.fov < minFov || camera.fov > maxFov) {
			camera.fov = MathUtils.clamp(camera.fov, minFov, maxFov);
			camera.updateProjectionMatrix();
		}

		var oldRadius = _tbRadius;
		_tbRadius = calculateTbRadius(camera);

		if (oldRadius < _tbRadius - EPS || oldRadius > _tbRadius + EPS) {
			var scale = (_gizmos.scale.x + _gizmos.scale.y + _gizmos.scale.z) / 3;
			var newRadius = _tbRadius / scale;
			var curve = new EllipseCurve(0, 0, newRadius, newRadius);
			var points = curve.getPoints(_curvePts);
			var curveGeometry = new BufferGeometry().setFromPoints(points);

			for (gizmo in _gizmos.children) {
				_gizmos.children[gizmo].geometry = curveGeometry;
			}
		}
	}

	camera.lookAt(_gizmos.position);
}

public function setStateFromJSON(json:String):Void {
	var state = JSON.parse(json);

	if (state.arcballState != null) {
		_cameraMatrixState.fromArray(state.arcballState.cameraMatrix.elements);
		_cameraMatrixState.decompose(camera.position, camera.quaternion, camera.scale);

		camera.up.copy(state.arcballState.cameraUp);
		camera.near = state.arcballState.cameraNear;
		camera.far = state.arcballState.cameraFar;

		camera.zoom = state.arcballState.cameraZoom;

		if (camera.isPerspectiveCamera) {
			camera.fov = state.arcballState.cameraFov;
		}

		_gizmoMatrixState.fromArray(state.arcballState.gizmoMatrix.elements);
		_gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

		camera.updateMatrix();
		camera.updateProjectionMatrix();

		_gizmos.updateMatrix();

		_tbRadius = calculateTbRadius(camera);
		var gizmoTmp = new Matrix4().copy(_gizmoMatrixState0);
		makeGizmos(_gizmos.position, _tbRadius);
		_gizmoMatrixState0.copy(gizmoTmp);

		camera.lookAt(_gizmos.position);
		updateTbState(STATE.IDLE, false);

		dispatchEvent(_changeEvent);
	}
}


//listeners

function onWindowResize():Void {
	var scale = (_gizmos.scale.x + _gizmos.scale.y + _gizmos.scale.z) / 3;
	_tbRadius = calculateTbRadius(camera);

	var newRadius = _tbRadius / scale;
	var curve = new EllipseCurve(0, 0, newRadius, newRadius);
	var points = curve.getPoints(_curvePts);
	var curveGeometry = new BufferGeometry().setFromPoints(points);


	for (gizmo in _gizmos.children) {
		_gizmos.children[gizmo].geometry = curveGeometry;
	}

	dispatchEvent(_changeEvent);
}

function onContextMenu(event:Event):Void {
	if (!enabled) {
		return;
	}

	for (i in 0...mouseActions.length) {
		if (mouseActions[i].mouse == 2) {
			//prevent only if button 2 is actually used
			event.preventDefault();
			break;
		}
	}
}

function onPointerCancel():Void {
	_touchStart.splice(0, _touchStart.length);
	_touchCurrent.splice(0, _touchCurrent.length);
	_input = INPUT.NONE;
}

function onPointerDown(event:Event):Void {
	if (event.button == 0 && event.isPrimary) {
		_downValid = true;
		_downEvents.push(event);
		_downStart = performance.now();
	} else {
		_downValid = false;
	}

	if (event.pointerType == 'touch' && _input != INPUT.CURSOR) {
		_touchStart.push(event);
		_touchCurrent.push(event);

		switch (_input) {
			case INPUT.NONE:
				//singleStart
				_input = INPUT.ONE_FINGER;
				onSinglePanStart(event, 'ROTATE');

				window.addEventListener('pointermove', _onPointerMove);
				window.addEventListener('pointerup', _onPointerUp);

				break;

			case INPUT.ONE_FINGER:
			case INPUT.ONE_FINGER_SWITCHED:
				//doubleStart
				_input = INPUT.TWO_FINGER;

				onRotateStart();
				onPinchStart();
				onDoublePanStart();

				break;

			case INPUT.TWO_FINGER:
				//multipleStart
				_input = INPUT.MULT_FINGER;
				onTriplePanStart(event);
				break;
		}
	} else if (event.pointerType != 'touch' && _input == INPUT.NONE) {
		var modifier = null;

		if (event.ctrlKey || event.metaKey) {
			modifier = 'CTRL';
		} else if (event.shiftKey) {
			modifier = 'SHIFT';
		}

		_mouseOp = getOpFromAction(event.button, modifier);
		if (_mouseOp != null) {
			window.addEventListener('pointermove', _on
onPointerMove);
window.addEventListener('pointerup', _onPointerUp);

//singleStart
_input = INPUT.CURSOR;
_button = event.button;
onSinglePanStart(event, _mouseOp);
}

function onPointerMove(event:Event):Void {
	if (event.pointerType == 'touch' && _input != INPUT.CURSOR) {
		switch (_input) {
			case INPUT.ONE_FINGER:
				//singleMove
				updateTouchEvent(event);

				onSinglePanMove(event, STATE.ROTATE);
				break;

			case INPUT.ONE_FINGER_SWITCHED:
				var movement = calculatePointersDistance(_touchCurrent[0], event) * _devPxRatio;

				if (movement >= _switchSensibility) {
					//singleMove
					_input = INPUT.ONE_FINGER;
					updateTouchEvent(event);

					onSinglePanStart(event, 'ROTATE');
					break;
				}

				break;

			case INPUT.TWO_FINGER:
				//rotate/pan/pinchMove
				updateTouchEvent(event);

				onRotateMove();
				onPinchMove();
				onDoublePanMove();

				break;

			case INPUT.MULT_FINGER:
				//multMove
				updateTouchEvent(event);

				onTriplePanMove(event);
				break;
		}
	} else if (event.pointerType != 'touch' && _input == INPUT.CURSOR) {
		var modifier = null;

		if (event.ctrlKey || event.metaKey) {
			modifier = 'CTRL';
		} else if (event.shiftKey) {
			modifier = 'SHIFT';
		}

		var mouseOpState = getOpStateFromAction(_button, modifier);

		if (mouseOpState != null) {
			onSinglePanMove(event, mouseOpState);
		}
	}

	//checkDistance
	if (_downValid) {
		var movement = calculatePointersDistance(_downEvents[_downEvents.length - 1], event) * _devPxRatio;
		if (movement > _movementThreshold) {
			_downValid = false;
		}
	}
}

function onPointerUp(event:Event):Void {
	if (event.pointerType == 'touch' && _input != INPUT.CURSOR) {
		var nTouch = _touchCurrent.length;

		for (i in 0...nTouch) {
			if (_touchCurrent[i].pointerId == event.pointerId) {
				_touchCurrent.splice(i, 1);
				_touchStart.splice(i, 1);
				break;
			}
		}

		switch (_input) {
			case INPUT.ONE_FINGER:
			case INPUT.ONE_FINGER_SWITCHED:
				//singleEnd
				window.removeEventListener('pointermove', _onPointerMove);
				window.removeEventListener('pointerup', _onPointerUp);

				_input = INPUT.NONE;
				onSinglePanEnd();

				break;

			case INPUT.TWO_FINGER:
				//doubleEnd
				onDoublePanEnd(event);
				onPinchEnd(event);
				onRotateEnd(event);

				//switching to singleStart
				_input = INPUT.ONE_FINGER_SWITCHED;

				break;

			case INPUT.MULT_FINGER:
				if (_touchCurrent.length == 0) {
					window.removeEventListener('pointermove', _onPointerMove);
					window.removeEventListener('pointerup', _onPointerUp);

					//multCancel
					_input = INPUT.NONE;
					onTriplePanEnd();
				}

				break;
		}
	} else if (event.pointerType != 'touch' && _input == INPUT.CURSOR) {
		window.removeEventListener('pointermove', _onPointerMove);
		window.removeEventListener('pointerup', _onPointerUp);

		_input = INPUT.NONE;
		onSinglePanEnd();
		_button = -1;
	}

	if (event.isPrimary) {
		if (_downValid) {
			var downTime = event.timeStamp - _downEvents[_downEvents.length - 1].timeStamp;

			if (downTime <= _maxDownTime) {
				if (_nclicks == 0) {
					//first valid click detected
					_nclicks = 1;
					_clickStart = performance.now();
				} else {
					var clickInterval = event.timeStamp - _clickStart;
					var movement = calculatePointersDistance(_downEvents[1], _downEvents[0]) * _devPxRatio;

					if (clickInterval <= _maxInterval && movement <= _posThreshold) {
						//second valid click detected
						//fire double tap and reset values
						_nclicks = 0;
						_downEvents.splice(0, _downEvents.length);
						onDoubleTap(event);
					} else {
						//new 'first click'
						_nclicks = 1;
						_downEvents.shift();
						_clickStart = performance.now();
					}
				}
			} else {
				_downValid = false;
				_nclicks = 0;
				_downEvents.splice(0, _downEvents.length);
			}
		} else {
			_nclicks = 0;
			_downEvents.splice(0, _downEvents.length);
		}
	}
}

function onWheel(event:Event):Void {
	if (enabled && enableZoom) {
		var modifier = null;

		if (event.ctrlKey || event.metaKey) {
			modifier = 'CTRL';
		} else if (event.shiftKey) {
			modifier = 'SHIFT';
		}

		var mouseOp = getOpFromAction('WHEEL', modifier);

		if (mouseOp != null) {
			event.preventDefault();
			dispatchEvent(_startEvent);

			var notchDeltaY = 125; //distance of one notch of mouse wheel
			var sgn = event.deltaY / notchDeltaY;

			var size = 1;

			if (sgn > 0) {
				size = 1 / scaleFactor;
			} else if (sgn < 0) {
				size = scaleFactor;
			}

			switch (mouseOp) {
				case 'ZOOM':
					updateTbState(STATE.SCALE, true);

					if (sgn > 0) {
						size = 1 / Math.pow(scaleFactor, sgn);
					} else if (sgn < 0) {
						size = Math.pow(scaleFactor, -sgn);
					}

					if (cursorZoom && enablePan) {
						var scalePoint:Vector3;

						if (camera.isOrthographicCamera) {
							scalePoint = unprojectOnTbPlane(camera, event.clientX, event.clientY, domElement).applyQuaternion(camera.quaternion).multiplyScalar(1 / camera.zoom).add(_gizmos.position);
						} else if (camera.isPerspectiveCamera) {
							scalePoint = unprojectOnTbPlane(camera, event.clientX, event.clientY, domElement).applyQuaternion(camera.quaternion).add(_gizmos.position);
						}

						applyTransformMatrix(scale(size, scalePoint));
					} else {
						applyTransformMatrix(scale(size, _gizmos.position));
					}

					if (_grid != null) {
						disposeGrid();
						drawGrid();
					}

					updateTbState(STATE.IDLE, false);

					dispatchEvent(_changeEvent);
					dispatchEvent(_endEvent);

					break;

				case 'FOV':
					if (camera.isPerspectiveCamera) {
						updateTbState(STATE.FOV, true);


						//Vertigo effect

						//	  fov / 2
						//		|\
						//		| \
						//		|  \
						//	x	|	\
						//		| 	 \
						//		| 	  \
						//		| _ _ _\
						//			y

						//check for iOs shift shortcut
						if (event.deltaX != 0) {
							sgn = event.deltaX / notchDeltaY;

							size = 1;

							if (sgn > 0) {
								size = 1 / Math.pow(scaleFactor, sgn);
							} else if (sgn < 0) {
								size = Math.pow(scaleFactor, -sgn);
							}
						}

						_v3_1.setFromMatrixPosition(_cameraMatrixState);
						var x = _v3_1.distanceTo(_gizmos.position);
						var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

						//check min and max distance
						xNew = MathUtils.clamp(xNew, minDistance, maxDistance);

						var y = x * Math.tan(MathUtils.DEG2RAD * camera.fov * 0.5);

						//calculate new fov
						var newFov = MathUtils.RAD2DEG * (Math.atan(y / xNew) * 2);

						//check min and max fov
						if (newFov > maxFov) {
							newFov = maxFov;
						} else if (newFov < minFov) {
							newFov = minFov;
						}

						var newDistance = y / Math.tan(MathUtils.DEG2RAD * (newFov / 2));
						size = x / newDistance;

						setFov(newFov);
						applyTransformMatrix(scale(size, _gizmos.position, false));
					}

					if (_grid != null) {
						disposeGrid();
						drawGrid();
					}

					updateTbState(STATE.IDLE, false);

					dispatchEvent(_changeEvent);
					dispatchEvent(_endEvent);

					break;
			}
		}
	}
}

export { ArcballControls };