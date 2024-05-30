function setTbRadius(value:Float) {
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

function makeGizmos(tbCenter:Vector3D, tbRadius:Float) {
    var curve = new EllipseCurve(0, 0, tbRadius, tbRadius);
    var points = curve.getPoints(_curvePts);

    //geometry
    var curveGeometry = new BufferGeometry().setFromPoints(points);

    //material
    var curveMaterialX = new LineBasicMaterial({ color: 0xff8080, fog: false, transparent: true, opacity: 0.6 });
    var curveMaterialY = new LineBasicMaterial({ color: 0x80ff80, fog: false, transparent: true, opacity: 0.6 });
    var curveMaterialZ = new LineBasicMaterial({ color: 0x8080ff, fog: false, transparent: true, opacity: 0.6 });

    //line
    var gizmoX = new Line(curveGeometry, curveMaterialX);
    var gizmoY = new Line(curveGeometry, curveMaterialY);
    var gizmoZ = new Line(curveGeometry, curveMaterialZ);

    var rotation = Math.PI * 0.5;
    gizmoX.rotation.x = rotation;
    gizmoY.rotation.y = rotation;

    //setting state
    _gizmoMatrixState0.identity().setPosition(tbCenter);
    _gizmoMatrixState.copy(_gizmoMatrixState0);

    if (camera.zoom != 1) {
        //adapt gizmos size to camera zoom
        var size = 1 / camera.zoom;
        _scaleMatrix.makeScale(size, size, size);
        _translationMatrix.makeTranslation(-tbCenter.x, -tbCenter.y, -tbCenter.z);

        _gizmoMatrixState.premultiply(_translationMatrix).premultiply(_scaleMatrix);
        _translationMatrix.makeTranslation(tbCenter.x, tbCenter.y, tbCenter.z);
        _gizmoMatrixState.premultiply(_translationMatrix);
    }

    _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

    //

    _gizmos.traverse(function (object) {
        if (object.isLine) {
            object.geometry.dispose();
            object.material.dispose();
        }
    });

    _gizmos.clear();

    //

    _gizmos.add(gizmoX);
    _gizmos.add(gizmoY);
    _gizmos.add(gizmoZ);
}

function onFocusAnim(time:Float, point:Vector3D, cameraMatrix:Matrix4, gizmoMatrix:Matrix4) {
    if (_timeStart == -1) {
        //animation start
        _timeStart = time;
    }

    if (_state == STATE.ANIMATION_FOCUS) {
        var deltaTime = time - _timeStart;
        var animTime = deltaTime / focusAnimationTime;

        _gizmoMatrixState.copy(gizmoMatrix);

        if (animTime >= 1) {
            //animation end

            _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

            focus(point, scaleFactor);

            _timeStart = -1;
            updateTbState(STATE.IDLE, false);
            activateGizmos(false);

            dispatchEvent(_changeEvent);
        } else {
            var amount = easeOutCubic(animTime);
            var size = ((1 - amount) + (scaleFactor * amount));

            _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
            focus(point, size, amount);

            dispatchEvent(_changeEvent);
            var self = this;
            _animationId = window.requestAnimationFrame(function (t) {
                self.onFocusAnim(t, point, cameraMatrix, gizmoMatrix.clone());
            });
        }
    } else {
        //interrupt animation

        _animationId = -1;
        _timeStart = -1;
    }
}

function onRotationAnim(time:Float, rotationAxis:Vector3D, w0:Float) {
    if (_timeStart == -1) {
        //animation start
        _anglePrev = 0;
        _angleCurrent = 0;
        _timeStart = time;
    }

    if (_state == STATE.ANIMATION_ROTATE) {
        //w = w0 + alpha * t
        var deltaTime = (time - _timeStart) / 1000;
        var w = w0 + ((-dampingFactor) * deltaTime);

        if (w > 0) {
            //tetha = 0.5 * alpha * t^2 + w0 * t + tetha0
            _angleCurrent = 0.5 * (-dampingFactor) * Math.pow(deltaTime, 2) + w0 * deltaTime + 0;
            applyTransformMatrix(rotate(rotationAxis, _angleCurrent));
            dispatchEvent(_changeEvent);
            var self = this;
            _animationId = window.requestAnimationFrame(function (t) {
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
        //interrupt animation

        _animationId = -1;
        _timeStart = -1;

        if (_state != STATE.ROTATE) {
            activateGizmos(false);
            dispatchEvent(_changeEvent);
        }
    }
}

function pan(p0:Vector3D, p1:Vector3D, adjust:Bool = false) {
    var movement = p0.clone().sub(p1);

    if (camera.isOrthographicCamera) {
        //adjust movement amount
        movement.multiplyScalar(1 / camera.zoom);
    } else if (camera.isPerspectiveCamera && adjust) {
        //adjust movement amount
        _v3_1.setFromMatrixPosition(_cameraMatrixState0); //camera's initial position
        _v3_2.setFromMatrixPosition(_gizmoMatrixState0); //gizmo's initial position
        var distanceFactor = _v3_1.distanceTo(_v3_2) / camera.position.distanceTo(_gizmos.position);
        movement.multiplyScalar(1 / distanceFactor);
    }

    _v3_1.set(movement.x, movement.y, 0).applyQuaternion(camera.quaternion);

    _m4_1.makeTranslation(_v3_1.x, _v3_1.y, _v3_1.z);

    setTransformationMatrices(_m4_1, _m4_1);
    return _transformation;
}

function reset() {
    camera.zoom = _zoom0;

    if (camera.isPerspectiveCamera) {
        camera.fov = _fov0;
    }

    camera.near = _nearPos;
    camera.far = _farPos;
    _cameraMatrixState.copy(_cameraMatrixState0);
    _cameraMatrixState.decompose(camera.position, camera.quaternion, camera.scale);
    camera.up.copy(_up0);

    camera.updateMatrix();
    camera.updateProjectionMatrix();

    _gizmoMatrixState.copy(_gizmoMatrixState0);
    _gizmoMatrixState0.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
    _gizmos.updateMatrix();

    _tbRadius = calculateTbRadius(camera);
    makeGizmos(_gizmos.position, _tbRadius);

    camera.lookAt(_gizmos.position);

    updateTbState(STATE.IDLE, false);

    dispatchEvent(_changeEvent);
}

function rotate(axis:Vector3D, angle:Float) {
    var point = _gizmos.position; //rotation center
    _translationMatrix.makeTranslation(-point.x, -point.y, -point.z);
    _rotationMatrix.makeRotationAxis(axis, -angle);

    //rotate camera
    _m4_1.makeTranslation(point.x, point.y, point.z);
    _m4_1.multiply(_rotationMatrix);
    _m4_1.multiply(_translationMatrix);

    setTransformationMatrices(_m4_1);

    return _transformation;
}

function copyState() {
    var state;
    if (camera.isOrthographicCamera) {
        state = JSON.stringify({ arcballState: {
            cameraFar: camera.far,
            cameraMatrix: camera.matrix,
            cameraNear: camera.near,
            cameraUp: camera.up,
            cameraZoom: camera.zoom,
            gizmoMatrix: _gizmos.matrix
        }});
    } else if (camera.isPerspectiveCamera) {
        state = JSON.stringify({ arcballState: {
            cameraFar: camera.far,
            cameraFov: camera.fov,
            cameraMatrix: camera.matrix,
            cameraNear: camera.near,
            cameraUp: camera.up,
            cameraZoom: camera.zoom,
            gizmoMatrix: _gizmos.matrix
        }});
    }

    navigator.clipboard.writeText(state);
}

function pasteState() {
    var self = this;
    navigator.clipboard.readText().then(function resolved(value) {
        self.setStateFromJSON(value);
    });
}

function saveState() {
    _cameraMatrixState0.copy(camera.matrix);
    _gizmoMatrixState0.copy(_gizmos.matrix);
    _nearPos = camera.near;
    _farPos = camera.far;
    _zoom0 = camera.zoom;
    _up0.copy(camera.up);

    if (camera.isPerspectiveCamera) {
        _fov0 = camera.fov;
    }
}

function scale(size:Float, point:Vector3D, scaleGizmos:Bool = true) {
    _scalePointTemp.copy(point);
    var sizeInverse = 1 / size;

    if (camera.isOrthographicCamera) {
        //camera zoom
        camera.zoom = _zoomState;
        camera.zoom *= size;

        //check min and max zoom
        if (camera.zoom > maxZoom) {
            camera.zoom = maxZoom;
            sizeInverse = _zoomState / maxZoom;
        } else if (camera.zoom < minZoom) {
            camera.zoom = minZoom;
            sizeInverse = _zoomState / minZoom;
        }

        camera.updateProjectionMatrix();

        _v3_1.setFromMatrixPosition(_gizmoMatrixState); //gizmos position

        //scale gizmos so they appear in the same spot having the same dimension
        _scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);
        _translationMatrix.makeTranslation(-_v3_1.x, -_v3_1.y, -_v3_1.z);

        _m4_2.makeTranslation(_v3_1.x, _v3_1.y, _v3_1.z).multiply(_scaleMatrix);
        _m4_2.multiply(_translationMatrix);

        //move camera and gizmos to obtain pinch effect
        _scalePointTemp.sub(_v3_1);

        var amount = _scalePointTemp.clone().multiplyScalar(sizeInverse);
        _scalePointTemp.sub(amount);

        _m4_1.makeTranslation(_scalePointTemp.x, _scalePointTemp.y, _scalePointTemp.z);
        _m4_2.premultiply(_m4_1);

        setTransformationMatrices(_m4_1, _m4_2);
        return _transformation;
    } else if (camera.isPerspectiveCamera) {
        _v3_1.setFromMatrixPosition(_cameraMatrixState);
        _v3_2.setFromMatrixPosition(_gizmoMatrixState);

        //move camera
        var distance = _v3_1.distanceTo(_scalePointTemp);
        var amount = distance - (distance * sizeInverse);

        //check min and max distance
        var newDistance = distance - amount;
        if (newDistance < minDistance) {
            sizeInverse = minDistance / distance;
            amount = distance - (distance * sizeInverse);
        } else if (newDistance > maxDistance) {
            sizeInverse = maxDistance / distance;
            amount = distance - (distance * sizeInverse);
        }

        _offset.copy(_scalePointTemp).sub(_v3_1).normalize().multiplyScalar(amount);

        _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

        if (scaleGizmos) {
            //scale gizmos so they appear in the same spot having the same dimension
            var pos = _v3_2;

            distance = pos.distanceTo(_scalePointTemp);
            amount = distance - (distance * sizeInverse);
            _offset.copy(_scalePointTemp).sub(pos).normalize().multiplyScalar(amount);

            _translationMatrix.makeTranslation(pos.x, pos.y, pos.z);
            _scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);

            _m4_2.makeTranslation(_offset.x, _offset.y, _offset.z).multiply(_translationMatrix);
            _m4_2.multiply(_scaleMatrix);

            _translationMatrix.makeTranslation(-pos.x, -pos.y, -pos.z);

            _m4_2.multiply(_translationMatrix);
            setTransformationMatrices(_m4_1, _m4_2);

        } else {
            setTransformationMatrices(_m4_1);
        }

        return _transformation;
    }
}

function setFov(value:Float) {
    if (camera.isPerspectiveCamera) {
        camera.fov = MathUtils.clamp(value, minFov, maxFov);
        camera.updateProjectionMatrix();
    }
}

function setTransformationMatrices(camera:Matrix4 = null, gizmos:Matrix4 = null) {
    if (camera != null) {
        if (_transformation.camera != null) {
            _transformation.camera.copy(camera);
        } else {
            _transformation.camera = camera.clone();
        }
    } else {
        _transformation.camera = null;
    }

    if (gizmos != null) {
        if (_transformation.gizmos != null) {
            _transformation.gizmos.copy(gizmos);
        } else {
            _transformation.gizmos = gizmos.clone();
        }
    } else {
        _transformation.gizmos = null;
    }
}