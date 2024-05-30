class ArcballControls {
  public function onSinglePanEnd():Void {
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
            self.onRotationAnim(t, rotationAxis, Math.min(w, _wMax));
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

  public function onDoubleTap(event:Dynamic):Void {
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
    }
    dispatchEvent(_endEvent);
  }

  public function onDoublePanStart():Void {
    if (enabled && enablePan) {
      dispatchEvent(_startEvent);
      updateTbState(STATE.PAN, true);
      setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2, (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      _startCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement, true));
      _currentCursorPosition.copy(_startCursorPosition);
      activateGizmos(false);
    }
  }

  public function onDoublePanMove():Void {
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

  public function onDoublePanEnd():Void {
    updateTbState(STATE.IDLE, false);
    dispatchEvent(_endEvent);
  }

  public function onRotateStart():Void {
    if (enabled && enableRotate) {
      dispatchEvent(_startEvent);
      updateTbState(STATE.ZROTATE, true);
      _startFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);
      _currentFingerRotation = _startFingerRotation;
      camera.getWorldDirection(_rotationAxis);
      if (!enablePan && !enableZoom) {
        activateGizmos(true);
      }
    }
  }

  public function onRotateMove():Void {
    if (enabled && enableRotate) {
      setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2, (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      var rotationPoint;
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
      var amount = Math.PI * (_startFingerRotation - _currentFingerRotation) / 180;
      applyTransformMatrix(zRotate(rotationPoint, amount));
      dispatchEvent(_changeEvent);
    }
  }

  public function onRotateEnd():Void {
    updateTbState(STATE.IDLE, false);
    activateGizmos(false);
    dispatchEvent(_endEvent);
  }

  public function onPinchStart():Void {
    if (enabled && enableZoom) {
      dispatchEvent(_startEvent);
      updateTbState(STATE.SCALE, true);
      _startFingerDistance = calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]);
      _currentFingerDistance = _startFingerDistance;
      activateGizmos(false);
    }
  }

  public function onPinchMove():Void {
    if (enabled && enableZoom) {
      setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2, (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      var minDistance = 12;
      if (_state != STATE.SCALE) {
        _startFingerDistance = _currentFingerDistance;
        updateTbState(STATE.SCALE, true);
      }
      _currentFingerDistance = Math.max(calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]), minDistance * _devPxRatio);
      var amount = _currentFingerDistance / _startFingerDistance;
      var scalePoint;
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

  public function onPinchEnd():Void {
    updateTbState(STATE.IDLE, false);
    dispatchEvent(_endEvent);
  }

  public function onTriplePanStart():Void {
    if (enabled && enableZoom) {
      dispatchEvent(_startEvent);
      updateTbState(STATE.SCALE, true);
      var clientX = 0;
      var clientY = 0;
      var nFingers = _touchCurrent.length;
      for (i in 0...nFingers) {
        clientX += _touchCurrent[i].clientX;
        clientY += _touchCurrent[i].clientY;
      }
      setCenter(clientX / nFingers, clientY / nFingers);
      _startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
      _currentCursorPosition.copy(_startCursorPosition);
    }
  }

  public function onTriplePanMove():Void {
    if (enabled && enableZoom) {
      var clientX = 0;
      var clientY = 0;
      var nFingers = _touchCurrent.length;
      for (i in 0...nFingers) {
        clientX += _touchCurrent[i].clientX;
        clientY += _touchCurrent[i].clientY;
      }
      setCenter(clientX / nFingers, clientY / nFingers);
      var screenNotches = 8;
      _currentCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
      var movement = _currentCursorPosition.y - _startCursorPosition.y;
      var size = 1;
      if (movement < 0) {
        size = 1 / Math.pow(scaleFactor, -movement * screenNotches);
      } else if (movement > 0) {
        size = Math.pow(scaleFactor, movement * screenNotches);
      }
      _v3_1.setFromMatrixPosition(_cameraMatrixState);
      var x = _v3_1.distanceTo(_gizmos.position);
      var xNew = x / size;
      xNew = Math.max(Math.min(xNew, maxDistance), minDistance);
      var y = x * Math.tan(_fovState * Math.PI / 360);
      var newFov = Math.atan(y / xNew) * 2 * 180 / Math.PI;
      newFov = Math.max(Math.min(newFov, maxFov), minFov);
      var newDistance = y / Math.tan(newFov * Math.PI / 360);
      size = x / newDistance;
      _v3_2.setFromMatrixPosition(_gizmoMatrixState);
      setFov(newFov);
      applyTransformMatrix(scale(size, _v3_2, false));
      _offset.copy(_gizmos.position).sub(camera.position).normalize().multiplyScalar(newDistance / x);
      _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
      dispatchEvent(_changeEvent);
    }
  }

  public function onTriplePanEnd():Void {
    updateTbState(STATE.IDLE, false);
    dispatchEvent(_endEvent);
    //dispatchEvent(_changeEvent);
  }

  public function setCenter(clientX:Float, clientY:Float):Void {
    _center.x = clientX;
    _center.y = clientY;
  }

  public function initializeMouseActions():Void {
    setMouseAction('PAN', 0, 'CTRL');
    setMouseAction('PAN', 2);
    setMouseAction('ROTATE', 0);
    setMouseAction('ZOOM', 'WHEEL');
    setMouseAction('ZOOM', 1);
    setMouseAction('FOV', 'WHEEL', 'SHIFT');
    setMouseAction('FOV', 1, 'SHIFT');
  }

  public function compareMouseAction(action1:Dynamic, action2:Dynamic):Bool {
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
}