class ArcballControls {
  private var _mouseActions:Array<Dynamic>;
  private var _cameraMatrixState:Matrix4;
  private var _cameraMatrixState0:Matrix4;
  private var _cameraProjectionState:Matrix4;
  private var _zoom0:Float;
  private var _zoomState:Float;
  private var _fov0:Float;
  private var _fovState:Float;
  private var _nearPos0:Float;
  private var _nearPos:Float;
  private var _farPos0:Float;
  private var _farPos:Float;
  private var _up0:Vector3;
  private var _upState:Vector3;
  private var _gizmos:Object3D;
  private var _gizmoMatrixState:Matrix4;
  private var _gizmoMatrixState0:Matrix4;
  private var _gizmoMatrixStateTemp:Matrix4;
  private var _cameraMatrixStateTemp:Matrix4;
  private var _translationMatrix:Matrix4;
  private var _rotationMatrix:Matrix4;
  private var _quat:Quaternion;
  private var _rotationAxis:Vector3;
  private var _offset:Vector3;
  private var _tbRadius:Float;
  private var _grid:GridHelper;
  private var _gridPosition:Vector3;
  private var _v2_1:Vector2;
  private var _m4_1:Matrix4;

  public function new() {
    _mouseActions = [];
    _cameraMatrixState = new Matrix4();
    _cameraMatrixState0 = new Matrix4();
    _cameraProjectionState = new Matrix4();
    _zoom0 = 1;
    _zoomState = 1;
    _fov0 = 50;
    _fovState = 50;
    _nearPos0 = 0.1;
    _nearPos = 0.1;
    _farPos0 = 1000;
    _farPos = 1000;
    _up0 = new Vector3(0, 1, 0);
    _upState = new Vector3(0, 1, 0);
    _gizmos = new Object3D();
    _gizmoMatrixState = new Matrix4();
    _gizmoMatrixState0 = new Matrix4();
    _gizmoMatrixStateTemp = new Matrix4();
    _cameraMatrixStateTemp = new Matrix4();
    _translationMatrix = new Matrix4();
    _rotationMatrix = new Matrix4();
    _quat = new Quaternion();
    _rotationAxis = new Vector3();
    _offset = new Vector3();
    _tbRadius = 1;
    _grid = null;
    _gridPosition = new Vector3();
    _v2_1 = new Vector2();
    _m4_1 = new Matrix4();
  }

  public function setMouseAction(operation:String, mouse:String, key:String):Bool {
    const operationInput:Array<String> = ["PAN", "ROTATE", "ZOOM", "FOV"];
    const mouseInput:Array<String> = ["0", "1", "2", "WHEEL"];
    const keyInput:Array<String> = ["CTRL", "SHIFT", null];
    let state;

    if (!operationInput.includes(operation) || !mouseInput.includes(mouse) || !keyInput.includes(key)) {
      return false;
    }

    if (mouse == "WHEEL") {
      if (operation != "ZOOM" && operation != "FOV") {
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

    const action:Dynamic = {
      operation: operation,
      mouse: mouse,
      key: key,
      state: state
    };

    for (i in 0..._mouseActions.length) {
      if (_mouseActions[i].mouse == action.mouse && _mouseActions[i].key == action.key) {
        _mouseActions.splice(i, 1, action);
        return true;
      }
    }

    _mouseActions.push(action);
    return true;
  }

  public function unsetMouseAction(mouse:String, key:String):Bool {
    for (i in 0..._mouseActions.length) {
      if (_mouseActions[i].mouse == mouse && _mouseActions[i].key == key) {
        _mouseActions.splice(i, 1);
        return true;
      }
    }

    return false;
  }

  public function getOpFromAction(mouse:String, key:String):String {
    let action:Dynamic;

    for (i in 0..._mouseActions.length) {
      action = _mouseActions[i];
      if (action.mouse == mouse && action.key == key) {
        return action.operation;
      }
    }

    if (key != null) {
      for (i in 0..._mouseActions.length) {
        action = _mouseActions[i];
        if (action.mouse == mouse && action.key == null) {
          return action.operation;
        }
      }
    }

    return null;
  }

  public function getOpStateFromAction(mouse:String, key:String):String {
    let action:Dynamic;

    for (i in 0..._mouseActions.length) {
      action = _mouseActions[i];
      if (action.mouse == mouse && action.key == key) {
        return action.state;
      }
    }

    if (key != null) {
      for (i in 0..._mouseActions.length) {
        action = _mouseActions[i];
        if (action.mouse == mouse && action.key == null) {
          return action.state;
        }
      }
    }

    return null;
  }

  public function getAngle(p1:Vector2, p2:Vector2):Float {
    return Math.atan2(p2.y - p1.y, p2.x - p1.x) * 180 / Math.PI;
  }

  public function updateTouchEvent(event:Dynamic):Void {
    for (i in 0..._touchCurrent.length) {
      if (_touchCurrent[i].pointerId == event.pointerId) {
        _touchCurrent.splice(i, 1, event);
        break;
      }
    }
  }

  public function applyTransformMatrix(transformation:Dynamic):Void {
    if (transformation.camera != null) {
      _m4_1.copy(_cameraMatrixState).premultiply(transformation.camera);
      _m4_1.decompose(_camera.position, _camera.quaternion, _camera.scale);
      _camera.updateMatrix();

      //update camera up vector
      if (_state == STATE.ROTATE || _state == STATE.ZROTATE || _state == STATE.ANIMATION_ROTATE) {
        _camera.up.copy(_upState).applyQuaternion(_camera.quaternion);
      }
    }

    if (transformation.gizmos != null) {
      _m4_1.copy(_gizmoMatrixState).premultiply(transformation.gizmos);
      _m4_1.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
      _gizmos.updateMatrix();
    }

    if (_state == STATE.SCALE || _state == STATE.FOCUS || _state == STATE.ANIMATION_FOCUS) {
      _tbRadius = calculateTbRadius(_camera);

      if (_adjustNearFar) {
        const cameraDistance:Float = _camera.position.distanceTo(_gizmos.position);

        const bb:Box3 = new Box3();
        bb.setFromObject(_gizmos);
        const sphere:Sphere = new Sphere();
        bb.getBoundingSphere(sphere);

        const adjustedNearPosition:Float = Math.max(_nearPos0, sphere.radius + sphere.center.length());
        const regularNearPosition:Float = cameraDistance - _initialNear;

        const minNearPos:Float = Math.min(adjustedNearPosition, regularNearPosition);
        _camera.near = cameraDistance - minNearPos;

        const adjustedFarPosition:Float = Math.min(_farPos0, -sphere.radius + sphere.center.length());
        const regularFarPosition:Float = cameraDistance - _initialFar;

        const minFarPos:Float = Math.min(adjustedFarPosition, regularFarPosition);
        _camera.far = cameraDistance - minFarPos;

        _camera.updateProjectionMatrix();
      } else {
        let update:Bool = false;

        if (_camera.near != _initialNear) {
          _camera.near = _initialNear;
          update = true;
        }

        if (_camera.far != _initialFar) {
          _camera.far = _initialFar;
          update = true;
        }

        if (update) {
          _camera.updateProjectionMatrix();
        }
      }
    }
  }

  public function calculateAngularSpeed(p0:Float, p1:Float, t0:Float, t1:Float):Float {
    const s:Float = p1 - p0;
    const t:Float = (t1 - t0) / 1000;
    if (t == 0) {
      return 0;
    }

    return s / t;
  }

  public function calculatePointersDistance(p0:Vector2, p1:Vector2):Float {
    return Math.sqrt(Math.pow(p1.x - p0.x, 2) + Math.pow(p1.y - p0.y, 2));
  }

  public function calculateRotationAxis(vec1:Vector3, vec2:Vector3):Vector3 {
    _rotationMatrix.extractRotation(_cameraMatrixState);
    _quat.setFromRotationMatrix(_rotationMatrix);

    _rotationAxis.crossVectors(vec1, vec2).applyQuaternion(_quat);
    return _rotationAxis.normalize().clone();
  }

  public function calculateTbRadius(camera:Camera):Float {
    const distance:Float = camera.position.distanceTo(_gizmos.position);

    if (camera.type == "PerspectiveCamera") {
      const halfFovV:Float = MathUtils.DEG2RAD * camera.fov * 0.5; //vertical fov/2 in radians
      const halfFovH:Float = Math.atan((camera.aspect) * Math.tan(halfFovV)); //horizontal fov/2 in radians
      return Math.tan(Math.min(halfFovV, halfFovH)) * distance * _radiusFactor;
    } else if (camera.type == "OrthographicCamera") {
      return Math.min(camera.top, camera.right) * _radiusFactor;
    }

    return 0;
  }

  public function focus(point:Vector3, size:Float, amount:Float = 1):Void {
    //move center of camera (along with gizmos) towards point of interest
    _offset.copy(point).sub(_gizmos.position).multiplyScalar(amount);
    _translationMatrix.makeTranslation(_offset.x, _offset.y, _offset.z);

    _gizmoMatrixStateTemp.copy(_gizmoMatrixState);
    _gizmoMatrixState.premultiply(_translationMatrix);
    _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

    _cameraMatrixStateTemp.copy(_cameraMatrixState);
    _cameraMatrixState.premultiply(_translationMatrix);
    _cameraMatrixState.decompose(_camera.position, _camera.quaternion, _camera.scale);

    //apply zoom
    if (_enableZoom) {
      applyTransformMatrix(scale(size, _gizmos.position));
    }

    _gizmoMatrixState.copy(_gizmoMatrixStateTemp);
    _cameraMatrixState.copy(_cameraMatrixStateTemp);
  }

  public function drawGrid():Void {
    if (_scene != null) {
      const color:Int = 0x888888;
      const multiplier:Float = 3;
      let size:Float, divisions:Float, maxLength:Float, tick:Float;

      if (_camera.isOrthographicCamera) {
        const width:Float = _camera.right - _camera.left;
        const height:Float = _camera.bottom - _camera.top;

        maxLength = Math.max(width, height);
        tick = maxLength / 20;

        size = maxLength / _camera.zoom * multiplier;
        divisions = size / tick * _camera.zoom;
      } else if (_camera.isPerspectiveCamera) {
        const distance:Float = _camera.position.distanceTo(_gizmos.position);
        const halfFovV:Float = MathUtils.DEG2RAD * _camera.fov * 0.5;
        const halfFovH:Float = Math.atan((_camera.aspect) * Math.tan(halfFovV));

        maxLength = Math.tan(Math.max(halfFovV, halfFovH)) * distance * 2;
        tick = maxLength / 20;

        size = maxLength * multiplier;
        divisions = size / tick;
      }

      if (_grid == null) {
        _grid = new GridHelper(size, divisions, color, color);
        _grid.position.copy(_gizmos.position);
        _gridPosition.copy(_grid.position);
        _grid.quaternion.copy(_camera.quaternion);
        _grid.rotateX(Math.PI * 0.5);

        _scene.add(_grid);
      }
    }
  }

  public function dispose():Void {
    if (_animationId != -1) {
      window.cancelAnimationFrame(_animationId);
    }

    _domElement.removeEventListener("pointerdown", _onPointerDown);
    _domElement.removeEventListener("pointercancel", _onPointerCancel);
    _domElement.removeEventListener("wheel", _onWheel);
    _domElement.removeEventListener("contextmenu", _onContextMenu);

    window.removeEventListener("pointermove", _onPointerMove);
    window.removeEventListener("pointerup", _onPointerUp);

    window.removeEventListener("resize", _onWindowResize);

    if (_scene !== null) _scene.remove(_gizmos);
    disposeGrid();
  }

  public function disposeGrid():Void {
    if (_grid != null && _scene != null) {
      _scene.remove(_grid);
      _grid = null;
    }
  }

  public function easeOutCubic(t:Float):Float {
    return 1 - Math.pow(1 - t, 3);
  }

  public function activateGizmos(isActive:Bool):Void {
    const gizmoX:Object3D = _gizmos.children[0];
    const gizmoY:Object3D = _gizmos.children[1];
    const gizmoZ:Object3D = _gizmos.children[2];

    if (isActive) {
      gizmoX.material.setValues({ opacity: 1 });
      gizmoY.material.setValues({ opacity: 1 });
      gizmoZ.material.setValues({ opacity: 1 });
    } else {
      gizmoX.material.setValues({ opacity: 0.6 });
      gizmoY.material.setValues({ opacity: 0.6 });
      gizmoZ.material.setValues({ opacity: 0.6 });
    }
  }

  public function getCursorNDC(cursorX:Float, cursorY:Float, canvas:Dynamic):Vector2 {
    const canvasRect:Dynamic = canvas.getBoundingClientRect();
    _v2_1.setX(((cursorX - canvasRect.left) / canvasRect.width) * 2 - 1);
    _v2_1.setY(((canvasRect.bottom - cursorY) / canvasRect.height) * 2 - 1);
    return _v2_1.clone();
  }

  public function getCursorPosition(cursorX:Float, cursorY:Float, canvas:Dynamic):Vector2 {
    _v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));
    _v2_1.x *= (_camera.right - _camera.left) * 0.5;
    _v2_1.y *= (_camera.top - _camera.bottom) * 0.5;
    return _v2_1.clone();
  }

  public function setCamera(camera:Camera):Void {
    camera.lookAt(_target);
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
    _nearPos0 = camera.position.distanceTo(_target) - camera.near;
    _nearPos = _initialNear;

    _initialFar = camera.far;
    _farPos0 = camera.position.distanceTo(_target) - camera.far;
    _farPos = _initialFar;

    _up0.copy(camera.up);
    _upState.copy(camera.up);

    _camera = camera;
    _camera.updateProjectionMatrix();

    //making gizmos
    _tbRadius = calculateTbRadius(_camera);
    makeGizmos(_target, _tbRadius);
  }

  public function setGizmosVisible(value:Bool):Void {
    _gizmos.visible = value;
    dispatchEvent(_changeEvent);
  }
}