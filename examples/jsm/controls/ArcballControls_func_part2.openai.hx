package three.js.examples.jm.controls;

import three.js.*;
import js.Browser;
import js.html.*;

class ArcballControls {
    // ...

    public function onSinglePanEnd() {
        if (this._state == STATE.ROTATE) {
            if (!this.enableRotate) return;
            if (this.enableAnimations) {
                var deltaTime = (Browser.window.performance.now() - this._timeCurrent);
                if (deltaTime < 120) {
                    var w = Math.abs((this._wPrev + this._wCurr) / 2);
                    var self = this;
                    this._animationId = Browser.window.requestAnimationFrame(function(t) {
                        self.updateTbState(STATE.ANIMATION_ROTATE, true);
                        var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);
                        self.onRotationAnim(t, rotationAxis, Math.min(w, self.wMax));
                    });
                } else {
                    this.updateTbState(STATE.IDLE, false);
                    this.activateGizmos(false);
                    this.dispatchEvent(_changeEvent);
                }
            } else {
                this.updateTbState(STATE.IDLE, false);
                this.activateGizmos(false);
                this.dispatchEvent(_changeEvent);
            }
        } else if (this._state == STATE.PAN || this._state == STATE.IDLE) {
            this.updateTbState(STATE.IDLE, false);
            if (this.enableGrid) {
                this.disposeGrid();
            }
            this.activateGizmos(false);
            this.dispatchEvent(_changeEvent);
        }
        this.dispatchEvent(_endEvent);
    }

    public function onDoubleTap(event: MouseEvent) {
        if (this.enabled && this.enablePan && this.scene != null) {
            this.dispatchEvent(_startEvent);
            this.setCenter(event.clientX, event.clientY);
            var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);
            if (hitP != null && this.enableAnimations) {
                if (this._animationId != -1) {
                    Browser.window.cancelAnimationFrame(this._animationId);
                }
                this._timeStart = -1;
                this._animationId = Browser.window.requestAnimationFrame(function(t) {
                    this.updateTbState(STATE.ANIMATION_FOCUS, true);
                    this.onFocusAnim(t, hitP, this._cameraMatrixState, this._gizmoMatrixState);
                });
            } else if (hitP != null && !this.enableAnimations) {
                this.updateTbState(STATE.FOCUS, true);
                this.focus(hitP, this.scaleFactor);
                this.updateTbState(STATE.IDLE, false);
                this.dispatchEvent(_changeEvent);
            }
        }
        this.dispatchEvent(_endEvent);
    }

    public function onDoublePanStart() {
        if (this.enabled && this.enablePan) {
            this.dispatchEvent(_startEvent);
            this.updateTbState(STATE.PAN, true);
            this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
            this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
            this._currentCursorPosition.copy(this._startCursorPosition);
            this.activateGizmos(false);
        }
    }

    public function onDoublePanMove() {
        if (this.enabled && this.enablePan) {
            this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
            if (this._state != STATE.PAN) {
                this.updateTbState(STATE.PAN, true);
                this._startCursorPosition.copy(this._currentCursorPosition);
            }
            this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
            this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition, true));
            this.dispatchEvent(_changeEvent);
        }
    }

    public function onDoublePanEnd() {
        this.updateTbState(STATE.IDLE, false);
        this.dispatchEvent(_endEvent);
    }

    public function onRotateStart() {
        if (this.enabled && this.enableRotate) {
            this.dispatchEvent(_startEvent);
            this.updateTbState(STATE.ZROTATE, true);
            this._startFingerRotation = this.getAngle(this._touchCurrent[1], this._touchCurrent[0]) + this.getAngle(this._touchStart[1], this._touchStart[0]);
            this._currentFingerRotation = this._startFingerRotation;
            this.camera.getWorldDirection(this._rotationAxis);
            if (!this.enablePan && !this.enableZoom) {
                this.activateGizmos(true);
            }
        }
    }

    public function onRotateMove() {
        if (this.enabled && this.enableRotate) {
            this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
            var rotationPoint;
            if (this._state != STATE.ZROTATE) {
                this.updateTbState(STATE.ZROTATE, true);
                this._startFingerRotation = this._currentFingerRotation;
            }
            this._currentFingerRotation = this.getAngle(this._touchCurrent[1], this._touchCurrent[0]) + this.getAngle(this._touchStart[1], this._touchStart[0]);
            if (!this.enablePan) {
                rotationPoint = new Vector3().setFromMatrixPosition(this._gizmoMatrixState);
            } else {
                this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
                rotationPoint = this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement).applyQuaternion(this.camera.quaternion).multiplyScalar(1 / this.camera.zoom).add(this._v3_2);
            }
            var amount = MathUtils.DEG2RAD * (this._startFingerRotation - this._currentFingerRotation);
            this.applyTransformMatrix(this.zRotate(rotationPoint, amount));
            this.dispatchEvent(_changeEvent);
        }
    }

    public function onRotateEnd() {
        this.updateTbState(STATE.IDLE, false);
        this.activateGizmos(false);
        this.dispatchEvent(_endEvent);
    }

    public function onPinchStart() {
        if (this.enabled && this.enableZoom) {
            this.dispatchEvent(_startEvent);
            this.updateTbState(STATE.SCALE, true);
            this._startFingerDistance = this.calculatePointersDistance(this._touchCurrent[0], this._touchCurrent[1]);
            this._currentFingerDistance = this._startFingerDistance;
            this.activateGizmos(false);
        }
    }

    public function onPinchMove() {
        if (this.enabled && this.enableZoom) {
            this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
            var minDistance = 12;
            if (this._state != STATE.SCALE) {
                this._startFingerDistance = this._currentFingerDistance;
                this.updateTbState(STATE.SCALE, true);
            }
            this._currentFingerDistance = Math.max(this.calculatePointersDistance(this._touchCurrent[0], this._touchCurrent[1]), minDistance * this._devPxRatio);
            var amount = this._currentFingerDistance / this._startFingerDistance;
            var scalePoint;
            if (!this.enablePan) {
                scalePoint = this._gizmos.position;
            } else {
                if (this.camera.isOrthographicCamera) {
                    scalePoint = this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement).applyQuaternion(this.camera.quaternion).multiplyScalar(1 / this.camera.zoom).add(this._gizmos.position);
                } else if (this.camera.isPerspectiveCamera) {
                    scalePoint = this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement).applyQuaternion(this.camera.quaternion).add(this._gizmos.position);
                }
            }
            this.applyTransformMatrix(this.scale(amount, scalePoint));
            this.dispatchEvent(_changeEvent);
        }
    }

    public function onPinchEnd() {
        this.updateTbState(STATE.IDLE, false);
        this.dispatchEvent(_endEvent);
    }

    public function onTriplePanStart() {
        if (this.enabled && this.enableZoom) {
            this.dispatchEvent(_startEvent);
            this.updateTbState(STATE.SCALE, true);
            var clientX = 0;
            var clientY = 0;
            var nFingers = this._touchCurrent.length;
            for (i in 0...nFingers) {
                clientX += this._touchCurrent[i].clientX;
                clientY += this._touchCurrent[i].clientY;
            }
            this.setCenter(clientX / nFingers, clientY / nFingers);
            this._startCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
            this._currentCursorPosition.copy(this._startCursorPosition);
        }
    }

    public function onTriplePanMove() {
        if (this.enabled && this.enableZoom) {
            var clientX = 0;
            var clientY = 0;
            var nFingers = this._touchCurrent.length;
            for (i in 0...nFingers) {
                clientX += this._touchCurrent[i].clientX;
                clientY += this._touchCurrent[i].clientY;
            }
            this.setCenter(clientX / nFingers, clientY / nFingers);
            this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
            var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
            var size = 1;
            if (movement < 0) {
                size = 1 / Math.pow(this.scaleFactor, -movement * 8);
            } else if (movement > 0) {
                size = Math.pow(this.scaleFactor, movement * 8);
            }
            this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
            var x = this._v3_1.distanceTo(this._gizmos.position);
            var xNew = x / size;
            xNew = MathUtils.clamp(xNew, this.minDistance, this.maxDistance);
            var y = x * Math.tan(MathUtils.DEG2RAD * this._fovState * 0.5);
            var newFov = MathUtils.RAD2DEG * (Math.atan(y / xNew) * 2);
            newFov = MathUtils.clamp(newFov, this.minFov, this.maxFov);
            var newDistance = y / Math.tan(MathUtils.DEG2RAD * (newFov / 2));
            size = x / newDistance;
            this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
            this.setFov(newFov);
            this.applyTransformMatrix(this.scale(size, this._v3_2, false));
            this.dispatchEvent(_changeEvent);
        }
    }

    public function onTriplePanEnd() {
        this.updateTbState(STATE.IDLE, false);
        this.dispatchEvent(_endEvent);
    }

    public function setCenter(clientX: Float, clientY: Float) {
        _center.x = clientX;
        _center.y = clientY;
    }

    public function initializeMouseActions() {
        this.setMouseAction('PAN', 0, 'CTRL');
        this.setMouseAction('PAN', 2);
        this.setMouseAction('ROTATE', 0);
        this.setMouseAction('ZOOM', 'WHEEL');
        this.setMouseAction('ZOOM', 1);
        this.setMouseAction('FOV', 'WHEEL', 'SHIFT');
        this.setMouseAction('FOV', 1, 'SHIFT');
    }

    public function compareMouseAction(action1: MouseAction, action2: MouseAction) {
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