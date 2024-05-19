Here is the converted Haxe code:
```
package three.js.examples.jsm.controls;

import haxe.ds.Vector;

class ArcballControls {
    // member variables ...

    public function new() {}

    public function zRotate(point:Vector3, angle:Float) {
        _rotationMatrix.makeRotationAxis(_rotationAxis, angle);
        _translationMatrix.makeTranslation(-point.x, -point.y, -point.z);

        _m4_1.makeTranslation(point.x, point.y, point.z);
        _m4_1.multiply(_rotationMatrix);
        _m4_1.multiply(_translationMatrix);

        _v3_1.setFromMatrixPosition(_gizmoMatrixState).sub(point); // vector from rotation center to gizmo's position
        _v3_2.copy(_v3_1).applyAxisAngle(_rotationAxis, angle); // apply rotation
        _v3_2.sub(_v3_1);

        _m4_2.makeTranslation(_v3_2.x, _v3_2.y, _v3_2.z);

        setTransformationMatrices(_m4_1, _m4_2);
        return _transformation;
    }

    public function getRaycaster() {
        return _raycaster;
    }

    public function unprojectOnObj(cursor:Vector2, camera:Camera) {
        var raycaster = getRaycaster();
        raycaster.near = camera.near;
        raycaster.far = camera.far;
        raycaster.setFromCamera(cursor, camera);

        var intersect:Array<Intersection> = raycaster.intersectObjects(_scene.children, true);

        for (i in 0...intersect.length) {
            if (intersect[i].object.uuid != _gizmos.uuid && intersect[i].face != null) {
                return intersect[i].point.clone();
            }
        }

        return null;
    }

    public function unprojectOnTbSurface(camera:Camera, cursorX:Float, cursorY:Float, canvas:HTMLCanvasElement, tbRadius:Float) {
        if (camera.type == 'OrthographicCamera') {
            _v2_1.copy(getCursorPosition(cursorX, cursorY, canvas));
            _v3_1.set(_v2_1.x, _v2_1.y, 0);

            var x2 = Math.pow(_v2_1.x, 2);
            var y2 = Math.pow(_v2_1.y, 2);
            var r2 = Math.pow(tbRadius, 2);

            if (x2 + y2 <= r2 * 0.5) {
                // intersection with sphere
                _v3_1.setZ(Math.sqrt(r2 - (x2 + y2)));
            } else {
                // intersection with hyperboloid
                _v3_1.setZ((r2 * 0.5) / (Math.sqrt(x2 + y2)));
            }

            return _v3_1;
        } else if (camera.type == 'PerspectiveCamera') {
            // unproject cursor on the near plane
            _v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));

            _v3_1.set(_v2_1.x, _v2_1.y, -1);
            _v3_1.applyMatrix4(camera.projectionMatrixInverse);

            var rayDir = _v3_1.clone().normalize(); // unprojected ray direction

            // calculate intersection point between unprojected ray and trackball surface
            var h = _v3_1.z;
            var l = Math.sqrt(Math.pow(_v3_1.x, 2) + Math.pow(_v3_1.y, 2));
            var cameraGizmoDistance = camera.position.distanceTo(_gizmos.position);

            if (l == 0) {
                // ray aligned with camera
                rayDir.set(0, 0, 0);
                return rayDir;
            }

            var m = h / l;
            var q = cameraGizmoDistance;

            // calculate intersection point between unprojected ray and trackball surface
            var a = Math.pow(m, 2) + 1;
            var b = 2 * m * q;
            var c = Math.pow(q, 2) - Math.pow(tbRadius, 2);
            var delta = Math.pow(b, 2) - (4 * a * c);

            if (delta >= 0) {
                // intersection with sphere
                _v2_1.setX((-b - Math.sqrt(delta)) / (2 * a));
                _v2_1.setY(m * _v2_1.x + q);

                var angle = _v2_1.angle();

                if (angle >= 45) {
                    // if angle between intersection point and X' axis is >= 45°, return that point
                    // otherwise, calculate intersection point with hyperboloid
                    var rayLength = Math.sqrt(Math.pow(_v2_1.x, 2) + Math.pow((cameraGizmoDistance - _v2_1.y), 2));
                    rayDir.multiplyScalar(rayLength);
                    rayDir.z += cameraGizmoDistance;
                    return rayDir;
                }
            }

            // intersection with hyperboloid
            a = m;
            b = q;
            c = -Math.pow(tbRadius, 2) / 2;
            delta = Math.pow(b, 2) - (4 * a * c);

            _v2_1.setX((-b - Math.sqrt(delta)) / (2 * a));
            _v2_1.setY(m * _v2_1.x + q);

            var rayLength = Math.sqrt(Math.pow(_v2_1.x, 2) + Math.pow((cameraGizmoDistance - _v2_1.y), 2));
            rayDir.multiplyScalar(rayLength);
            rayDir.z += cameraGizmoDistance;
            return rayDir;
        }
    }

    public function unprojectOnTbPlane(camera:Camera, cursorX:Float, cursorY:Float, canvas:HTMLCanvasElement, initialDistance:Bool = false) {
        if (camera.type == 'OrthographicCamera') {
            _v2_1.copy(getCursorPosition(cursorX, cursorY, canvas));
            _v3_1.set(_v2_1.x, _v2_1.y, 0);
            return _v3_1.clone();
        } else if (camera.type == 'PerspectiveCamera') {
            _v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));

            _v3_1.set(_v2_1.x, _v2_1.y, -1);
            _v3_1.applyMatrix4(camera.projectionMatrixInverse);

            var rayDir = _v3_1.clone().normalize(); // unprojected ray direction

            var h = _v3_1.z;
            var l = Math.sqrt(Math.pow(_v3_1.x, 2) + Math.pow(_v3_1.y, 2));
            var cameraGizmoDistance;

            if (initialDistance) {
                cameraGizmoDistance = _v3_1.setFromMatrixPosition(_cameraMatrixState0).distanceTo(_v3_2.setFromMatrixPosition(_gizmoMatrixState0));
            } else {
                cameraGizmoDistance = camera.position.distanceTo(_gizmos.position);
            }

            if (l == 0) {
                // ray aligned with camera
                rayDir.set(0, 0, 0);
                return rayDir;
            }

            var m = h / l;
            var q = cameraGizmoDistance;

            // calculate intersection point between unprojected ray and plane
            var x = -q / m;

            var rayLength = Math.sqrt(Math.pow(q, 2) + Math.pow(x, 2));
            rayDir.multiplyScalar(rayLength);
            rayDir.z = 0;
            return rayDir;
        }
    }

    public function updateMatrixState() {
        // update camera and gizmos state
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

    public function updateTbState(newState:State, updateMatrices:Bool) {
        _state = newState;
        if (updateMatrices) {
            updateMatrixState();
        }
    }

    public function update() {
        // ...
    }

    public function setStateFromJSON(json:String) {
        // ...
    }

    // listeners
    function onWindowResize() {
        // ...
    }

    function onContextMenu(event:MouseEvent) {
        // ...
    }

    function onPointerCancel() {
        // ...
    }

    function onPointerDown(event:PointerEvent) {
        // ...
    }

    function onPointerMove(event:PointerEvent) {
        // ...
    }

    function onPointerUp(event:Pointer