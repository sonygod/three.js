package three.js.examples.jsm.controls;

class ArcballControls {
  // ...

  public function setTbRadius(value:Float) {
    radiusFactor = value;
    _tbRadius = calculateTbRadius(camera);

    var curve = new EllipseCurve(0, 0, _tbRadius, _tbRadius);
    var points = curve.getPoints(_curvePts);
    var curveGeometry = new BufferGeometry().setFromPoints(points);

    for (gizmo in _gizmos.children) {
      _gizmos.children[gizmo].geometry = curveGeometry;
    }

    dispatchEvent(_changeEvent);
  }

  public function makeGizmos(tbCenter:Vector3, tbRadius:Float) {
    var curve = new EllipseCurve(0, 0, tbRadius, tbRadius);
    var points = curve.getPoints(_curvePts);

    var curveGeometry = new BufferGeometry().setFromPoints(points);

    var curveMaterialX = new LineBasicMaterial({ color: 0xff8080, fog: false, transparent: true, opacity: 0.6 });
    var curveMaterialY = new LineBasicMaterial({ color: 0x80ff80, fog: false, transparent: true, opacity: 0.6 });
    var curveMaterialZ = new LineBasicMaterial({ color: 0x8080ff, fog: false, transparent: true, opacity: 0.6 });

    var gizmoX = new Line(curveGeometry, curveMaterialX);
    var gizmoY = new Line(curveGeometry, curveMaterialY);
    var gizmoZ = new Line(curveGeometry, curveMaterialZ);

    // ...

    _gizmos.traverse(function(object) {
      if (object.isLine) {
        object.geometry.dispose();
        object.material.dispose();
      }
    });

    _gizmos.clear();

    _gizmos.add(gizmoX);
    _gizmos.add(gizmoY);
    _gizmos.add(gizmoZ);
  }

  // ...

  public function onFocusAnim(time:Float, point:Vector3, cameraMatrix:Matrix4, gizmoMatrix:Matrix4) {
    if (_timeStart == -1) {
      _timeStart = time;
    }

    if (_state == STATE.ANIMATION_FOCUS) {
      var deltaTime = time - _timeStart;
      var animTime = deltaTime / focusAnimationTime;

      _gizmoMatrixState.copy(gizmoMatrix);

      if (animTime >= 1) {
        _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

        focus(point, scaleFactor);

        _timeStart = -1;
        updateTbState(STATE.IDLE, false);
        activateGizmos(false);

        dispatchEvent(_changeEvent);
      } else {
        var amount = easeOutCubic(animTime);
        var size = (1 - amount) + (scaleFactor * amount);

        _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

        focus(point, size, amount);

        dispatchEvent(_changeEvent);
        var self = this;
        _animationId = requestAnimationFrame(function(t) {
          self.onFocusAnim(t, point, cameraMatrix, gizmoMatrix.clone());
        });
      }
    } else {
      _animationId = -1;
      _timeStart = -1;
    }
  }

  // ...

  public function onRotationAnim(time:Float, rotationAxis:Vector3, w0:Float) {
    if (_timeStart == -1) {
      _anglePrev = 0;
      _angleCurrent = 0;
      _timeStart = time;
    }

    if (_state == STATE.ANIMATION_ROTATE) {
      var deltaTime = (time - _timeStart) / 1000;
      var w = w0 + (-dampingFactor * deltaTime);

      if (w > 0) {
        _angleCurrent = 0.5 * (-dampingFactor) * Math.pow(deltaTime, 2) + w0 * deltaTime + 0;
        applyTransformMatrix(rotate(rotationAxis, _angleCurrent));
        dispatchEvent(_changeEvent);
        var self = this;
        _animationId = requestAnimationFrame(function(t) {
          self.onRotationAnim(t, rotationAxis, w0);
        });
      } else {
        _animationId = -1;
        _timeStart = -1;

        updateTbState(STATE.IDLE, false);
        activateGizmos(false);

        dispatchEvent(_changeEvent);
      }
    } else {
      _animationId = -1;
      _timeStart = -1;

      if (_state != STATE.ROTATE) {
        activateGizmos(false);
        dispatchEvent(_changeEvent);
      }
    }
  }

  // ...
}