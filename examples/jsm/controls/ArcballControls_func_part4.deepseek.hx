class ArcballControls {
    // ...

    public function setTbRadius(value:Float):Void {
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

    public function makeGizmos(tbCenter:Vector3, tbRadius:Float):Void {
        var curve = new EllipseCurve(0, 0, tbRadius, tbRadius);
        var points = curve.getPoints(this._curvePts);

        var curveGeometry = new BufferGeometry().setFromPoints(points);

        var curveMaterialX = new LineBasicMaterial({color:0xff8080, fog:false, transparent:true, opacity:0.6});
        var curveMaterialY = new LineBasicMaterial({color:0x80ff80, fog:false, transparent:true, opacity:0.6});
        var curveMaterialZ = new LineBasicMaterial({color:0x8080ff, fog:false, transparent:true, opacity:0.6});

        var gizmoX = new Line(curveGeometry, curveMaterialX);
        var gizmoY = new Line(curveGeometry, curveMaterialY);
        var gizmoZ = new Line(curveGeometry, curveMaterialZ);

        var rotation = Math.PI * 0.5;
        gizmoX.rotation.x = rotation;
        gizmoY.rotation.y = rotation;

        this._gizmoMatrixState0.identity().setPosition(tbCenter);
        this._gizmoMatrixState.copy(this._gizmoMatrixState0);

        if (this.camera.zoom !== 1) {
            var size = 1 / this.camera.zoom;
            this._scaleMatrix.makeScale(size, size, size);
            this._translationMatrix.makeTranslation(-tbCenter.x, -tbCenter.y, -tbCenter.z);

            this._gizmoMatrixState.premultiply(this._translationMatrix).premultiply(this._scaleMatrix);
            this._translationMatrix.makeTranslation(tbCenter.x, tbCenter.y, tbCenter.z);
            this._gizmoMatrixState.premultiply(this._translationMatrix);
        }

        this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);

        this._gizmos.traverse(function (object) {
            if (object.isLine) {
                object.geometry.dispose();
                object.material.dispose();
            }
        });

        this._gizmos.clear();

        this._gizmos.add(gizmoX);
        this._gizmos.add(gizmoY);
        this._gizmos.add(gizmoZ);
    }

    // ...

    public function reset():Void {
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

    // ...

    public function copyState():Void {
        var state:String;
        if (this.camera.isOrthographicCamera) {
            state = haxe.Json.stringify({
                arcballState: {
                    cameraFar: this.camera.far,
                    cameraMatrix: this.camera.matrix,
                    cameraNear: this.camera.near,
                    cameraUp: this.camera.up,
                    cameraZoom: this.camera.zoom,
                    gizmoMatrix: this._gizmos.matrix
                }
            });
        } else if (this.camera.isPerspectiveCamera) {
            state = haxe.Json.stringify({
                arcballState: {
                    cameraFar: this.camera.far,
                    cameraFov: this.camera.fov,
                    cameraMatrix: this.camera.matrix,
                    cameraNear: this.camera.near,
                    cameraUp: this.camera.up,
                    cameraZoom: this.camera.zoom,
                    gizmoMatrix: this._gizmos.matrix
                }
            });
        }

        js.Browser.navigator.clipboard.writeText(state);
    }

    // ...

    public function saveState():Void {
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

    // ...

    public function setFov(value:Float):Void {
        if (this.camera.isPerspectiveCamera) {
            this.camera.fov = MathUtils.clamp(value, this.minFov, this.maxFov);
            this.camera.updateProjectionMatrix();
        }
    }

    // ...
}