class ArcballControlsFuncPart3 {
    private var mouseActions:Array<Dynamic>;
    private var _cameraMatrixState:Matrix4;
    private var _cameraMatrixState0:Matrix4;
    private var _cameraProjectionState:Matrix4;
    private var _zoom0:Float;
    private var _zoomState:Float;
    private var _initialNear:Float;
    private var _nearPos0:Float;
    private var _nearPos:Float;
    private var _initialFar:Float;
    private var _farPos0:Float;
    private var _farPos:Float;
    private var _up0:Vector3;
    private var _upState:Vector3;
    private var _tbRadius:Float;
    private var _gizmos:Object3D;
    private var _grid:GridHelper;
    private var _gridPosition:Vector3;
    private var _animationId:Int = -1;
    private var _onPointerDown:Function;
    private var _onPointerCancel:Function;
    private var _onWheel:Function;
    private var _onContextMenu:Function;
    private var _onPointerMove:Function;
    private var _onPointerUp:Function;
    private var _onWindowResize:Function;
    private var _v2_1:Vector2 = new Vector2();
    private var _fov0:Float;
    private var _fovState:Float;

    public function setMouseAction(operation:String, mouse:Dynamic, key:String = null):Bool {
        var operationInput = ["PAN", "ROTATE", "ZOOM", "FOV"];
        var mouseInput = [0, 1, 2, "WHEEL"];
        var keyInput = ["CTRL", "SHIFT", null];
        var state:Int;

        if (!operationInput.contains(operation) || !mouseInput.contains(mouse) || !keyInput.contains(key)) {
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

        var action = {
            operation: operation,
            mouse: mouse,
            key: key,
            state: state
        };

        for (i in 0...this.mouseActions.length) {
            if (this.mouseActions[i].mouse == action.mouse && this.mouseActions[i].key == action.key) {
                this.mouseActions.splice(i, 1, action);
                return true;
            }
        }

        this.mouseActions.push(action);
        return true;
    }

    public function setMouseAction(operation:String, mouse:Dynamic):Bool {
        return this.setMouseAction(operation, mouse, null);
    }

    public function unsetMouseAction(mouse:Dynamic, key:String = null):Bool {
        for (i in 0...this.mouseActions.length) {
            if (this.mouseActions[i].mouse == mouse && this.mouseActions[i].key == key) {
                this.mouseActions.splice(i, 1);
                return true;
            }
        }

        return false;
    }

    public function unsetMouseAction(mouse:Dynamic):Bool {
        return this.unsetMouseAction(mouse, null);
    }

    public function getOpFromAction(mouse:Dynamic, key:String):String {
        var action:Dynamic;

        for (i in 0...this.mouseActions.length) {
            action = this.mouseActions[i];
            if (action.mouse == mouse && action.key == key) {
                return action.operation;
            }
        }

        if (key != null) {
            for (i in 0...this.mouseActions.length) {
                action = this.mouseActions[i];
                if (action.mouse == mouse && action.key == null) {
                    return action.operation;
                }
            }
        }

        return null;
    }

    public function getOpStateFromAction(mouse:Dynamic, key:String):Int {
        var action:Dynamic;

        for (i in 0...this.mouseActions.length) {
            action = this.mouseActions[i];
            if (action.mouse == mouse && action.key == key) {
                return action.state;
            }
        }

        if (key != null) {
            for (i in 0...this.mouseActions.length) {
                action = this.mouseActions[i];
                if (action.mouse == mouse && action.key == null) {
                    return action.state;
                }
            }
        }

        return null;
    }

    public function getAngle(p1:PointerEvent, p2:PointerEvent):Float {
        return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX) * 180 / Math.PI;
    }

    public function updateTouchEvent(event:PointerEvent) {
        for (i in 0...this._touchCurrent.length) {
            if (this._touchCurrent[i].pointerId == event.pointerId) {
                this._touchCurrent.splice(i, 1, event);
                break;
            }
        }
    }

    public function applyTransformMatrix(transformation:Dynamic) {
        if (transformation.camera != null) {
            this._m4_1.copy(this._cameraMatrixState).premultiply(transformation.camera);
            this._m4_1.decompose(this.camera.position, this.camera.quaternion, this.camera.scale);
            this.camera.updateMatrix();

            if (this._state == STATE.ROTATE || this._state == STATE.ZROTATE || this._state == STATE.ANIMATION_ROTATE) {
                this.camera.up.copy(this._upState).applyQuaternion(this.camera.quaternion);
            }
        }

        if (transformation.gizmos != null) {
            this._m4_1.copy(this._gizmoMatrixState).premultiply(transformation.gizmos);
            this._m4_1.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
            this._gizmos.updateMatrix();
        }

        if (this._state == STATE.SCALE || this._state == STATE.FOCUS || this._state == STATE.ANIMATION_FOCUS) {
            this._tbRadius = this.calculateTbRadius(this.camera);

            if (this.adjustNearFar) {
                var cameraDistance = this.camera.position.distanceTo(this._gizmos.position);

                var bb = new Box3();
                bb.setFromObject(this._gizmos);
                var sphere = new Sphere();
                bb.getBoundingSphere(sphere);

                var adjustedNearPosition = Math.max(this._nearPos0, sphere.radius + sphere.center.length());
                var regularNearPosition = cameraDistance - this._initialNear;

                var minNearPos = Math.min(adjustedNearPosition, regularNearPosition);
                this.camera.near = cameraDistance - minNearPos;

                var adjustedFarPosition = Math.min(this._farPos0, -sphere.radius + sphere.center.length());
                var regularFarPosition = cameraDistance - this._initialFar;

                var minFarPos = Math.min(adjustedFarPosition, regularFarPosition);
                this.camera.far = cameraDistance - minFarPos;

                this.camera.updateProjectionMatrix();
            } else {
                var update = false;

                if (this.camera.near != this._initialNear) {
                    this.camera.near = this._initialNear;
                    update = true;
                }

                if (this.camera.far != this._initialFar) {
                    this.camera.far = this._initialFar;
                    update = true;
                }

                if (update) {
                    this.camera.updateProjectionMatrix();
                }
            }
        }
    }

    public function calculateAngularSpeed(p0:Float, p1:Float, t0:Float, t1:Float):Float {
        var s = p1 - p0;
        var t = (t1 - t0) / 1000;
        if (t == 0) {
            return 0;
        }

        return s / t;
    }

    public function calculatePointersDistance(p0:PointerEvent, p1:PointerEvent):Float {
        return Math.sqrt(Math.pow(p1.clientX - p0.clientX, 2) + Math.pow(p1.clientY - p0.clientY, 2));
    }

    public function calculateRotationAxis(vec1:Vector3, vec2:Vector3):Vector3 {
        this._rotationMatrix.extractRotation(this._cameraMatrixState);
        this._quat.setFromRotationMatrix(this._rotationMatrix);

        this._rotationAxis.crossVectors(vec1, vec2).applyQuaternion(this._quat);
        return this._rotationAxis.normalize().clone();
    }

    public function calculateTbRadius(camera:Camera):Float {
        var distance = camera.position.distanceTo(this._gizmos.position);

        if (camera.type == 'PerspectiveCamera') {
            var halfFovV = MathUtils.DEG2RAD * camera.fov * 0.5;
            var halfFovH = Math.atan((camera.aspect) * Math.tan(halfFovV));
            return Math.tan(Math.min(halfFovV, halfFovH)) * distance * this.radiusFactor;
        } else if (camera.type == 'OrthographicCamera') {
            return Math.min(camera.top, camera.right) * this.radiusFactor;
        }
    }

    public function focus(point:Vector3, size:Float, amount:Float = 1) {
        _offset.copy(point).sub(this._gizmos.position).multiplyScalar(amount);
        this._translationMatrix.makeTranslation(_offset.x, _offset.y, _offset.z);

        _gizmoMatrixStateTemp.copy(this._gizmoMatrixState);
        this._gizmoMatrixState.premultiply(this._translationMatrix);
        this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);

        _cameraMatrixStateTemp.copy(this._cameraMatrixState);
        this._cameraMatrixState.premultiply(this._translationMatrix);
        this._cameraMatrixState.decompose(this.camera.position, this.camera.quaternion, this.camera.scale);

        if (this.enableZoom) {
            this.applyTransformMatrix(this.scale(size, this._gizmos.position));
        }

        this._gizmoMatrixState.copy(_gizmoMatrixStateTemp);
        this._cameraMatrixState.copy(_cameraMatrixStateTemp);
    }

    public function drawGrid() {
        if (this.scene != null) {
            var color = 0x888888;
            var multiplier = 3;
            var size:Float;
            var divisions:Int;
            var maxLength:Float;
            var tick:Float;

            if (this.camera.isOrthographicCamera) {
                var width = this.camera.right - this.camera.left;
                var height = this.camera.bottom - this.camera.top;

                maxLength = Math.max(width, height);
                tick = maxLength / 20;

                size = maxLength / this.camera.zoom * multiplier;
                divisions = Std.int(size / tick * this.camera.zoom);
            } else if (this.camera.isPerspectiveCamera) {
                var distance = this.camera.position.distanceTo(this._gizmos.position);
                var halfFovV = MathUtils.DEG2RAD * this.camera.fov * 0.5;
                var halfFovH = Math.atan((this.camera.aspect) * Math.tan(halfFovV));

                maxLength = Math.tan(Math.max(halfFovV, halfFovH)) * distance * 2;
                tick = maxLength / 20;

                size = maxLength * multiplier;
                divisions = Std.int(size / tick);
            }

            if (this._grid == null) {
                this._grid = new GridHelper(size, divisions, color, color);
                this._grid.position.copy(this._gizmos.position);
                this._gridPosition.copy(this._grid.position);
                this._grid.quaternion.copy(this.camera.quaternion);
                this._grid.rotateX(Math.PI * 0.5);

                this.scene.add(this._grid);
            }
        }
    }

    public function dispose() {
        if (this._animationId != -1) {
            window.cancelAnimationFrame(this._animationId);
        }

        this.domElement.removeEventListener('pointerdown', this._onPointerDown);
        this.domElement.removeEventListener('pointercancel', this._onPointerCancel);
        this.domElement.removeEventListener('wheel', this._onWheel);
        this.domElement.removeEventListener('contextmenu', this._onContextMenu);

        window.removeEventListener('pointermove', this._onPointerMove);
        window.removeEventListener('pointerup', this._onPointerUp);

        window.removeEventListener('resize', this._onWindowResize);

        if (this.scene !== null) this.scene.remove(this._gizmos);
        this.disposeGrid();
    }

    public function disposeGrid() {
        if (this._grid != null && this.scene != null) {
            this.scene.remove(this._grid);
            this._grid = null;
        }
    }

    public function easeOutCubic(t:Float):Float {
        return 1 - Math.pow(1 - t, 3);
    }

    public function activateGizmos(isActive:Bool) {
        var gizmoX = this._gizmos.children[0];
        var gizmoY = this._gizmos.children[1];
        var gizmoZ = this._gizmos.children[2];

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

    public function getCursorNDC(cursorX:Float, cursorY:Float, canvas:HTMLElement):Vector2 {
        var canvasRect = canvas.getBoundingClientRect();
        this._v2_1.setX(((cursorX - canvasRect.left) / canvasRect.width) * 2 - 1);
        this._v2_1.setY(((canvasRect.bottom - cursorY) / canvasRect.height) * 2 - 1);
        return this._v2_1.clone();
    }

    public function getCursorPosition(cursorX:Float, cursorY:Float, canvas:HTMLElement):Vector2 {
        this._v2_1.copy(this.getCursorNDC(cursorX, cursorY, canvas));
        this._v2_1.x *= (this.camera.right - this.camera.left) * 0.5;
        this._v2_1.y *= (this.camera.top - this.camera.bottom) * 0.5;
        return this._v2_1.clone();
    }

    public function setCamera(camera:Camera) {
        camera.lookAt(this.target);
        camera.updateMatrix();

        if (camera.type == 'PerspectiveCamera') {
            this._fov0 = camera.fov;
            this._fovState = camera.fov;
        }

        this._cameraMatrixState0.copy(camera.matrix);
        this._cameraMatrixState.copy(this._cameraMatrixState0);
        this._cameraProjectionState.copy(camera.projectionMatrix);
        this._zoom0 = camera.zoom;
        this._zoomState = this._zoom0;

        this._initialNear = camera.near;
        this._nearPos0 = camera.position.distanceTo(this.target) - camera.near;
        this._nearPos = this._initialNear;

        this._initialFar = camera.far;
        this._farPos0 = camera.position.distanceTo(this.target) - camera.far;
        this._farPos = this._initialFar;

        this._up0.copy(camera.up);
        this._upState.copy(camera.up);

        this.camera = camera;
        this.camera.updateProjectionMatrix();

        this._tbRadius = this.calculateTbRadius(camera);
        this.makeGizmos(this.target, this._tbRadius);
    }

    public function setGizmosVisible(value:Bool) {
        this._gizmos.visible = value;
        this.dispatchEvent(_changeEvent);
    }
}