import three.EventDispatcher;
import three.Vector2;
import three.Vector3;
import three.Quaternion;
import three.Matrix4;
import three.PerspectiveCamera;
import three.OrthographicCamera;
import js.Browser;

class TransformControlsTouchInput {

    // ... existing code ...

    public function onSinglePanEnd():Void {

        if (this._state == STATE.ROTATE) {

            if (!this.enableRotate) {
                return;
            }

            if (this.enableAnimations) {

                //perform rotation animation
                var deltaTime = (Browser.window.performance.now() - this._timeCurrent);
                if (deltaTime < 120) {

                    var w = Math.abs((this._wPrev + this._wCurr) / 2);

                    var self = this;
                    this._animationId = Browser.window.requestAnimationFrame(function(t:Float):Void {

                        self.updateTbState(STATE.ANIMATION_ROTATE, true);
                        var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);

                        self.onRotationAnim(t, rotationAxis, Math.min(w, self.wMax));

                    });

                } else {

                    //cursor has been standing still for over 120 ms since last movement
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

    public function onDoubleTap(event:Dynamic):Void { // Assuming 'event' structure is consistent

        if (this.enabled && this.enablePan && this.scene != null) {

            this.dispatchEvent(_startEvent);

            this.setCenter(event.clientX, event.clientY);
            var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);

            if (hitP != null && this.enableAnimations) {

                var self = this;
                if (this._animationId != -1) {
                    Browser.window.cancelAnimationFrame(this._animationId);
                }

                this._timeStart = -1;
                this._animationId = Browser.window.requestAnimationFrame(function(t:Float):Void {
                    self.updateTbState(STATE.ANIMATION_FOCUS, true);
                    self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
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

    public function onDoublePanStart():Void {

        if (this.enabled && this.enablePan) {

            this.dispatchEvent(_startEvent);

            this.updateTbState(STATE.PAN, true);

            this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
            this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
            this._currentCursorPosition.copy(this._startCursorPosition);

            this.activateGizmos(false);

        }

    }

    public function onDoublePanMove():Void {

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

    public function onDoublePanEnd():Void {
        this.updateTbState(STATE.IDLE, false);
        this.dispatchEvent(_endEvent);
    }

    public function onRotateStart():Void {

        if (this.enabled && this.enableRotate) {

            this.dispatchEvent(_startEvent);

            this.updateTbState(STATE.ZROTATE, true);

            this._startFingerRotation = this.getAngle(this._touchCurrent[1], this._touchCurrent[0]) + this.getAngle(this._touchStart[1], this._touchStart[0]);
            this._currentFingerRotation = this._startFingerRotation;

            this.camera.getWorldDirection(this._rotationAxis); //rotation axis

            if (!this.enablePan && !this.enableZoom) {
                this.activateGizmos(true);
            }

        }

    }

    public function onRotateMove():Void {

        if (this.enabled && this.enableRotate) {

            this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);

            var rotationPoint:Vector3 = null;

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

            var amount = Math.PI / 180 * (this._startFingerRotation - this._currentFingerRotation); // MathUtils.DEG2RAD 

            this.applyTransformMatrix(this.zRotate(rotationPoint, amount));
            this.dispatchEvent(_changeEvent);

        }

    }

    public function onRotateEnd():Void {
        this.updateTbState(STATE.IDLE, false);
        this.activateGizmos(false);
        this.dispatchEvent(_endEvent);
    }

    public function onPinchStart():Void {

        if (this.enabled && this.enableZoom) {

            this.dispatchEvent(_startEvent);
            this.updateTbState(STATE.SCALE, true);

            this._startFingerDistance = this.calculatePointersDistance(this._touchCurrent[0], this._touchCurrent[1]);
            this._currentFingerDistance = this._startFingerDistance;

            this.activateGizmos(false);

        }

    }

    public function onPinchMove():Void {

        if (this.enabled && this.enableZoom) {

            this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
            var minDistance = 12; //minimum distance between fingers (in css pixels)

            if (this._state != STATE.SCALE) {
                this._startFingerDistance = this._currentFingerDistance;
                this.updateTbState(STATE.SCALE, true);
            }

            this._currentFingerDistance = Math.max(this.calculatePointersDistance(this._touchCurrent[0], this._touchCurrent[1]), minDistance * this._devPxRatio);
            var amount = this._currentFingerDistance / this._startFingerDistance;

            var scalePoint:Vector3 = null;

            if (!this.enablePan) {
                scalePoint = this._gizmos.position;

            } else {
                if (Std.is(this.camera, OrthographicCamera)) {
                    var orthoCam:OrthographicCamera = cast this.camera; // Explicit cast for clarity
                    scalePoint = this.unprojectOnTbPlane(orthoCam, _center.x, _center.y, this.domElement)
                        .applyQuaternion(orthoCam.quaternion)
                        .multiplyScalar(1 / orthoCam.zoom)
                        .add(this._gizmos.position);

                } else if (Std.is(this.camera, PerspectiveCamera)) {
                    var perspCam:PerspectiveCamera = cast this.camera; // Explicit cast for clarity
                    scalePoint = this.unprojectOnTbPlane(perspCam, _center.x, _center.y, this.domElement)
                        .applyQuaternion(perspCam.quaternion)
                        .add(this._gizmos.position);

                }

            }

            this.applyTransformMatrix(this.scale(amount, scalePoint));
            this.dispatchEvent(_changeEvent);

        }

    }

    public function onPinchEnd():Void {
        this.updateTbState(STATE.IDLE, false);
        this.dispatchEvent(_endEvent);
    }

    public function onTriplePanStart():Void {

        if (this.enabled && this.enableZoom) {

            this.dispatchEvent(_startEvent);

            this.updateTbState(STATE.SCALE, true);

            var clientX = 0.0;
            var clientY = 0.0;
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

    public function onTriplePanMove():Void {

        if (this.enabled && this.enableZoom) {

            var clientX = 0.0;
            var clientY = 0.0;
            var nFingers = this._touchCurrent.length;

            for (i in 0...nFingers) {
                clientX += this._touchCurrent[i].clientX;
                clientY += this._touchCurrent[i].clientY;
            }

            this.setCenter(clientX / nFingers, clientY / nFingers);

            var screenNotches = 8; //how many wheel notches corresponds to a full screen pan
            this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);

            var movement = this._currentCursorPosition.y - this._startCursorPosition.y;

            var size = 1.0;

            if (movement < 0) {
                size = 1 / (Math.pow(this.scaleFactor, -movement * screenNotches));

            } else if (movement > 0) {
                size = Math.pow(this.scaleFactor, movement * screenNotches);

            }

            this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
            var x = this._v3_1.distanceTo(this._gizmos.position);
            var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

            //check min and max distance
            xNew = Math.min(Math.max(xNew, this.minDistance), this.maxDistance); // MathUtils.clamp 

            var y = x * Math.tan(Math.PI / 180 * (this._fovState * 0.5)); // MathUtils.DEG2RAD 

            //calculate new fov
            var newFov =  Math.atan(y / xNew) * 2 * 180 / Math.PI; // MathUtils.RAD2DEG

            //check min and max fov
            newFov = Math.min(Math.max(newFov, this.minFov), this.maxFov); // MathUtils.clamp

            var newDistance = y / Math.tan(Math.PI / 180 * (newFov / 2)); // MathUtils.DEG2RAD 
            size = x / newDistance;
            this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);

            this.setFov(newFov);
            this.applyTransformMatrix(this.scale(size, this._v3_2, false));

            //adjusting distance
            _offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
            this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

            this.dispatchEvent(_changeEvent);
        }
    }

    public function onTriplePanEnd():Void {
        this.updateTbState(STATE.IDLE, false);
        this.dispatchEvent(_endEvent);
    }

    public function setCenter(clientX:Float, clientY:Float):Void {
        _center.x = clientX;
        _center.y = clientY;
    }

    public function initializeMouseActions():Void {
        this.setMouseAction('PAN', 0, 'CTRL');
        this.setMouseAction('PAN', 2);

        this.setMouseAction('ROTATE', 0);

        this.setMouseAction('ZOOM', 'WHEEL');
        this.setMouseAction('ZOOM', 1);

        this.setMouseAction('FOV', 'WHEEL', 'SHIFT');
        this.setMouseAction('FOV', 1, 'SHIFT');
    }

    public function compareMouseAction(action1:Dynamic, action2:Dynamic):Bool { 
        // Assuming consistent structure for action1 and action2

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

    // ... existing code ...

}