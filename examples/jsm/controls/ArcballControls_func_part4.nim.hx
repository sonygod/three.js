class ArcballControls {
    public function setTbRadius(value:Float) {
        this.radiusFactor = value;
        this._tbRadius = this.calculateTbRadius(this.camera);

        var curve = new EllipseCurve(0, 0, this._tbRadius, this._tbRadius);
        var points = curve.getPoints(this._curvePts);
        var curveGeometry = new BufferGeometry().setFromPoints(points);

        for (gizmo in this._gizmos.children) {
            this._gizmos.children[gizmo].geometry = curveGeometry;
        }

        this.dispatchEvent(_changeEvent);
    }

    public function makeGizmos(tbCenter:Vector3, tbRadius:Float) {
        var curve = new EllipseCurve(0, 0, tbRadius, tbRadius);
        var points = curve.getPoints(this._curvePts);

        //geometry
        var curveGeometry = new BufferGeometry().setFromPoints(points);

        //material
        var curveMaterialX = new LineBasicMaterial({color: 0xff8080, fog: false, transparent: true, opacity: 0.6});
        var curveMaterialY = new LineBasicMaterial({color: 0x80ff80, fog: false, transparent: true, opacity: 0.6});
        var curveMaterialZ = new LineBasicMaterial({color: 0x8080ff, fog: false, transparent: true, opacity: 0.6});

        //line
        var gizmoX = new Line(curveGeometry, curveMaterialX);
        var gizmoY = new Line(curveGeometry, curveMaterialY);
        var gizmoZ = new Line(curveGeometry, curveMaterialZ);

        var rotation = Math.PI * 0.5;
        gizmoX.rotation.x = rotation;
        gizmoY.rotation.y = rotation;

        //setting state
        this._gizmoMatrixState0.identity().setPosition(tbCenter);
        this._gizmoMatrixState.copy(this._gizmoMatrixState0);

        if (this.camera.zoom !== 1) {
            //adapt gizmos size to camera zoom
            var size = 1 / this.camera.zoom;
            this._scaleMatrix.makeScale(size, size, size);
            this._translationMatrix.makeTranslation(-tbCenter.x, -tbCenter.y, -tbCenter.z);

            this._gizmoMatrixState.premultiply(this._translationMatrix).premultiply(this._scaleMatrix);
            this._translationMatrix.makeTranslation(tbCenter.x, tbCenter.y, tbCenter.z);
            this._gizmoMatrixState.premultiply(this._translationMatrix);
        }

        this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);

        //

        this._gizmos.traverse(function(object) {
            if (object.isLine) {
                object.geometry.dispose();
                object.material.dispose();
            }
        });

        this._gizmos.clear();

        //

        this._gizmos.add(gizmoX);
        this._gizmos.add(gizmoY);
        this._gizmos.add(gizmoZ);
    }

    public function onFocusAnim(time:Float, point:Vector3, cameraMatrix:Matrix4, gizmoMatrix:Matrix4) {
        if (this._timeStart == -1) {
            //animation start
            this._timeStart = time;
        }

        if (this._state == STATE.ANIMATION_FOCUS) {
            var deltaTime = time - this._timeStart;
            var animTime = deltaTime / this.focusAnimationTime;

            this._gizmoMatrixState.copy(gizmoMatrix);

            if (animTime >= 1) {
                //animation end

                this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);

                this.focus(point, this.scaleFactor);

                this._timeStart = -1;
                this.updateTbState(STATE.IDLE, false);
                this.activateGizmos(false);

                this.dispatchEvent(_changeEvent);

            } else {
                var amount = this.easeOutCubic(animTime);
                var size = ((1 - amount) + (this.scaleFactor * amount));

                this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
                this.focus(point, size, amount);

                this.dispatchEvent(_changeEvent);
                var self = this;
                this._animationId = window.requestAnimationFrame(function(t) {
                    self.onFocusAnim(t, point, cameraMatrix, gizmoMatrix.clone());
                });
            }
        } else {
            //interrupt animation

            this._animationId = -1;
            this._timeStart = -1;
        }
    }

    public function onRotationAnim(time:Float, rotationAxis:Vector3, w0:Float) {
        if (this._timeStart == -1) {
            //animation start
            this._anglePrev = 0;
            this._angleCurrent = 0;
            this._timeStart = time;
        }

        if (this._state == STATE.ANIMATION_ROTATE) {
            //w = w0 + alpha * t
            var deltaTime = (time - this._timeStart) / 1000;
            var w = w0 + ((-this.dampingFactor) * deltaTime);

            if (w > 0) {
                //tetha = 0.5 * alpha * t^2 + w0 * t + tetha0
                this._angleCurrent = 0.5 * (-this.dampingFactor) * Math.pow(deltaTime, 2) + w0 * deltaTime + 0;
                this.applyTransformMatrix(this.rotate(rotationAxis, this._angleCurrent));
                this.dispatchEvent(_changeEvent);
                var self = this;
                this._animationId = window.requestAnimationFrame(function(t) {
                    self.onRotationAnim(t, rotationAxis, w0);
                });

            } else {
                this._animationId = -1;
                this._timeStart = -1;

                this.updateTbState(STATE.IDLE, false);
                this.activateGizmos(false);

                this.dispatchEvent(_changeEvent);
            }
        } else {
            //interrupt animation

            this._animationId = -1;
            this._timeStart = -1;

            if (this._state != STATE.ROTATE) {
                this.activateGizmos(false);
                this.dispatchEvent(_changeEvent);
            }
        }
    }

    public function pan(p0:Vector3, p1:Vector3, adjust:Bool = false) {
        var movement = p0.clone().sub(p1);

        if (this.camera.isOrthographicCamera) {
            //adjust movement amount
            movement.multiplyScalar(1 / this.camera.zoom);
        } else if (this.camera.isPerspectiveCamera && adjust) {
            //adjust movement amount
            this._v3_1.setFromMatrixPosition(this._cameraMatrixState0); //camera's initial position
            this._v3_2.setFromMatrixPosition(this._gizmoMatrixState0); //gizmo's initial position
            var distanceFactor = this._v3_1.distanceTo(this._v3_2) / this.camera.position.distanceTo(this._gizmos.position);
            movement.multiplyScalar(1 / distanceFactor);
        }

        this._v3_1.set(movement.x, movement.y, 0).applyQuaternion(this.camera.quaternion);

        this._m4_1.makeTranslation(this._v3_1.x, this._v3_1.y, this._v3_1.z);

        this.setTransformationMatrices(this._m4_1, this._m4_1);
        return _transformation;
    }

    public function reset() {
        this.camera.zoom = this._zoom0;

        if (this.camera.isPerspectiveCamera) {
            this.camera.fov = this._fov0;
        }

        this.camera.near = this._nearPos;
        this.camera.far = this._farPos;
        this._cameraMatrixState.copy(this._cameraMatrixState0);
        this._cameraMatrixState.decompose(this.camera.position, this.camera.quaternion, this.camera.scale);
        this.camera.up.copy(this._up0);

        this.camera.updateMatrix();
        this.camera.updateProjectionMatrix();

        this._gizmoMatrixState.copy(this._gizmoMatrixState0);
        this._gizmoMatrixState0.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
        this._gizmos.updateMatrix();

        this._tbRadius = this.calculateTbRadius(this.camera);
        this.makeGizmos(this._gizmos.position, this._tbRadius);

        this.camera.lookAt(this._gizmos.position);

        this.updateTbState(STATE.IDLE, false);

        this.dispatchEvent(_changeEvent);
    }

    public function rotate(axis:Vector3, angle:Float) {
        var point = this._gizmos.position; //rotation center
        this._translationMatrix.makeTranslation(-point.x, -point.y, -point.z);
        this._rotationMatrix.makeRotationAxis(axis, -angle);

        //rotate camera
        this._m4_1.makeTranslation(point.x, point.y, point.z);
        this._m4_1.multiply(this._rotationMatrix);
        this._m4_1.multiply(this._translationMatrix);

        this.setTransformationMatrices(this._m4_1);

        return _transformation;
    }

    public function copyState() {
        var state;
        if (this.camera.isOrthographicCamera) {
            state = JSON.stringify({arcballState: {
                cameraFar: this.camera.far,
                cameraMatrix: this.camera.matrix,
                cameraNear: this.camera.near,
                cameraUp: this.camera.up,
                cameraZoom: this.camera.zoom,
                gizmoMatrix: this._gizmos.matrix
            }});
        } else if (this.camera.isPerspectiveCamera) {
            state = JSON.stringify({arcballState: {
                cameraFar: this.camera.far,
                cameraFov: this.camera.fov,
                cameraMatrix: this.camera.matrix,
                cameraNear: this.camera.near,
                cameraUp: this.camera.up,
                cameraZoom: this.camera.zoom,
                gizmoMatrix: this._gizmos.matrix
            }});
        }

        navigator.clipboard.writeText(state);
    }

    public function pasteState() {
        var self = this;
        navigator.clipboard.readText().then(function resolved(value) {
            self.setStateFromJSON(value);
        });
    }

    public function saveState() {
        this._cameraMatrixState0.copy(this.camera.matrix);
        this._gizmoMatrixState0.copy(this._gizmos.matrix);
        this._nearPos = this.camera.near;
        this._farPos = this.camera.far;
        this._zoom0 = this.camera.zoom;
        this._up0.copy(this.camera.up);

        if (this.camera.isPerspectiveCamera) {
            this._fov0 = this.camera.fov;
        }
    }

    public function scale(size:Float, point:Vector3, scaleGizmos:Bool = true) {
        _scalePointTemp.copy(point);
        var sizeInverse = 1 / size;

        if (this.camera.isOrthographicCamera) {
            //camera zoom
            this.camera.zoom = this._zoomState;
            this.camera.zoom *= size;

            //check min and max zoom
            if (this.camera.zoom > this.maxZoom) {
                this.camera.zoom = this.maxZoom;
                sizeInverse = this._zoomState / this.maxZoom;
            } else if (this.camera.zoom < this.minZoom) {
                this.camera.zoom = this.minZoom;
                sizeInverse = this._zoomState / this.minZoom;
            }

            this.camera.updateProjectionMatrix();

            this._v3_1.setFromMatrixPosition(this._gizmoMatrixState); //gizmos position

            //scale gizmos so they appear in the same spot having the same dimension
            this._scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);
            this._translationMatrix.makeTranslation(-this._v3_1.x, -this._v3_1.y, -this._v3_1.z);

            this._m4_2.makeTranslation(this._v3_1.x, this._v3_1.y, this._v3_1.z).multiply(this._scaleMatrix);
            this._m4_2.multiply(this._translationMatrix);

            //move camera and gizmos to obtain pinch effect
            _scalePointTemp.sub(this._v3_1);

            var amount = _scalePointTemp.clone().multiplyScalar(sizeInverse);
            _scalePointTemp.sub(amount);

            this._m4_1.makeTranslation(_scalePointTemp.x, _scalePointTemp.y, _scalePointTemp.z);
            this._m4_2.premultiply(this._m4_1);

            this.setTransformationMatrices(this._m4_1, this._m4_2);
            return _transformation;

        } else if (this.camera.isPerspectiveCamera) {
            this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
            this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);

            //move camera
            var distance = this._v3_1.distanceTo(_scalePointTemp);
            var amount = distance - (distance * sizeInverse);

            //check min and max distance
            var newDistance = distance - amount;
            if (newDistance < this.minDistance) {
                sizeInverse = this.minDistance / distance;
                amount = distance - (distance * sizeInverse);
            } else if (newDistance > this.maxDistance) {
                sizeInverse = this.maxDistance / distance;
                amount = distance - (distance * sizeInverse);
            }

            _offset.copy(_scalePointTemp).sub(this._v3_1).normalize().multiplyScalar(amount);

            this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

            if (scaleGizmos) {
                //scale gizmos so they appear in the same spot having the same dimension
                var pos = this._v3_2;

                distance = pos.distanceTo(_scalePointTemp);
                amount = distance - (distance * sizeInverse);
                _offset.copy(_scalePointTemp).sub(this._v3_2).normalize().multiplyScalar(amount);

                this._translationMatrix.makeTranslation(pos.x, pos.y, pos.z);
                this._scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);

                this._m4_2.makeTranslation(_offset.x, _offset.y, _offset.z).multiply(this._translationMatrix);
                this._m4_2.multiply(this._scaleMatrix);

                this._translationMatrix.makeTranslation(-pos.x, -pos.y, -pos.z);

                this._m4_2.multiply(this._translationMatrix);
                this.setTransformationMatrices(this._m4_1, this._m4_2);

            } else {
                this.setTransformationMatrices(this._m4_1);
            }

            return _transformation;
        }
    }

    public function setFov(value:Float) {
        if (this.camera.isPerspectiveCamera) {
            this.camera.fov = MathUtils.clamp(value, this.minFov, this.maxFov);
            this.camera.updateProjectionMatrix();
        }
    }

    public function setTransformationMatrices(camera:Matrix4 = null, gizmos:Matrix4 = null) {
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
}