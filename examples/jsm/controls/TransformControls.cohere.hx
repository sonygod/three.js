import js.three.*;
import js.three.extras.core.BufferGeometry;
import js.three.extras.core.DoubleSide;
import js.three.extras.core.Raycaster;
import js.three.extras.core.Object3D;
import js.three.extras.core.PlaneGeometry;
import js.three.extras.core.Matrix4;
import js.three.extras.core.Euler;
import js.three.extras.core.Quaternion;
import js.three.extras.core.Vector3;
import js.three.extras.core.Float32BufferAttribute;
import js.three.extras.core.Line;
import js.three.extras.core.LineBasicMaterial;
import js.three.extras.core.Mesh;
import js.three.extras.core.MeshBasicMaterial;
import js.three.extras.core.BoxGeometry;
import js.three.extras.core.CylinderGeometry;
import js.three.extras.core.OctahedronGeometry;
import js.three.extras.core.SphereGeometry;
import js.three.extras.core.TorusGeometry;

class TransformControls extends Object3D {
    var _raycaster : Raycaster;
    var _tempVector : Vector3;
    var _tempVector2 : Vector3;
    var _tempQuaternion : Quaternion;
    var _unit : { X:Vector3, Y:Vector3, Z:Vector3 };
    var _changeEvent : Dynamic;
    var _mouseDownEvent : Dynamic;
    var _mouseUpEvent : Dynamic;
    var _objectChangeEvent : Dynamic;
    var _gizmo : TransformControlsGizmo;
    var _plane : TransformControlsPlane;

    public function new(camera : Camera, domElement : HtmlElement) {
        super();

        if (domElement == null) {
            trace("TransformControls: The second parameter 'domElement' is now mandatory.");
            domElement = cast window.document;
        }

        visible = false;
        this.domElement = domElement;
        domElement.style.touchAction = "none";

        _gizmo = new TransformControlsGizmo();
        add(_gizmo);

        _plane = new TransformControlsPlane();
        add(_plane);

        var scope = this;

        function defineProperty(propName : String, defaultValue : Dynamic) {
            var propValue = defaultValue;

            Object.defineProperty(scope, propName, {
                get: function() {
                    return propValue != null ? propValue : defaultValue;
                },
                set: function(value) {
                    if (propValue != value) {
                        propValue = value;
                        _plane[propName] = value;
                        _gizmo[propName] = value;
                        dispatchEvent({ type: propName + '-changed', value: value });
                        dispatchEvent(_changeEvent);
                    }
                }
            });

            scope[propName] = defaultValue;
            _plane[propName] = defaultValue;
            _gizmo[propName] = defaultValue;
        }

        defineProperty("camera", camera);
        defineProperty("object", null);
        defineProperty("enabled", true);
        defineProperty("axis", null);
        defineProperty("mode", "translate");
        defineProperty("translationSnap", null);
        defineProperty("rotationSnap", null);
        defineProperty("scaleSnap", null);
        defineProperty("space", "world");
        defineProperty("size", 1);
        defineProperty("dragging", false);
        defineProperty("showX", true);
        defineProperty("showY", true);
        defineProperty("showZ", true);

        var worldPosition = new Vector3();
        var worldPositionStart = new Vector3();
        var worldQuaternion = new Quaternion();
        var worldQuaternionStart = new Quaternion();
        var cameraPosition = new Vector3();
        var cameraQuaternion = new Quaternion();
        var pointStart = new Vector3();
        var pointEnd = new Vector3();
        var rotationAxis = new Vector3();
        var rotationAngle = 0;
        var eye = new Vector3();

        defineProperty("worldPosition", worldPosition);
        defineProperty("worldPositionStart", worldPositionStart);
        defineProperty("worldQuaternion", worldQuaternion);
        defineProperty("worldQuaternionStart", worldQuaternionStart);
        defineProperty("cameraPosition", cameraPosition);
        defineProperty("cameraQuaternion", cameraQuaternion);
        defineProperty("pointStart", pointStart);
        defineProperty("pointEnd", pointEnd);
        defineProperty("rotationAxis", rotationAxis);
        defineProperty("rotationAngle", rotationAngle);
        defineProperty("eye", eye);

        _offset = new Vector3();
        _startNorm = new Vector3();
        _endNorm = new Vector3();
        _cameraScale = new Vector3();

        _parentPosition = new Vector3();
        _parentQuaternion = new Quaternion();
        _parentQuaternionInv = new Quaternion();
        _parentScale = new Vector3();

        _worldScaleStart = new Vector3();
        _worldQuaternionInv = new Quaternion();
        _worldScale = new Vector3();

        _positionStart = new Vector3();
        _quaternionStart = new Quaternion();
        _scaleStart = new Vector3();

        _getPointer = bind(getPointer, this);
        _onPointerDown = bind(onPointerDown, this);
        _onPointerHover = bind(onPointerHover, this);
        _onPointerMove = bind(onPointerMove, this);
        _onPointerUp = bind(onPointerUp, this);

        domElement.addEventListener("pointerdown", _onPointerDown);
        domElement.addEventListener("pointermove", _onPointerHover);
        domElement.addEventListener("pointerup", _onPointerUp);
    }

    function updateMatrixWorld(force : Bool) {
        if (object != null) {
            object.updateMatrixWorld();

            if (object.parent == null) {
                throw "TransformControls: The attached 3D object must be a part of the scene graph.";
            } else {
                object.parent.matrixWorld.decompose(_parentPosition, _parentQuaternion, _parentScale);
            }

            object.matrixWorld.decompose(worldPosition, worldQuaternion, _worldScale);

            _parentQuaternionInv.copy(_parentQuaternion).invert();
            _worldQuaternionInv.copy(worldQuaternion).invert();
        }

        camera.updateMatrixWorld();
        camera.matrixWorld.decompose(cameraPosition, cameraQuaternion, _cameraScale);

        if (camera.isOrthographicCamera) {
            camera.getWorldDirection(eye).negate();
        } else {
            eye.copy(cameraPosition).sub(worldPosition).normalize();
        }

        super.updateMatrixWorld(force);
    }

    function pointerHover(pointer : Dynamic) {
        if (object == null || dragging) return;

        if (pointer != null) _raycaster.setFromCamera(pointer, camera);

        var intersect = intersectObjectWithRay(_gizmo.picker[mode], _raycaster);

        if (intersect) {
            axis = intersect.object.name;
        } else {
            axis = null;
        }
    }

    function pointerDown(pointer : Dynamic) {
        if (object == null || dragging || (pointer != null && pointer.button != 0)) return;

        if (axis != null) {
            if (pointer != null) _raycaster.setFromCamera(pointer, camera);

            var planeIntersect = intersectObjectWithRay(_plane, _raycaster, true);

            if (planeIntersect) {
                object.updateMatrixWorld();
                object.parent.updateMatrixWorld();

                _positionStart.copy(object.position);
                _quaternionStart.copy(object.quaternion);
                _scaleStart.copy(object.scale);

                object.matrixWorld.decompose(worldPositionStart, worldQuaternionStart, _worldScaleStart);

                pointStart.copy(planeIntersect.point).sub(worldPositionStart);
            }

            dragging = true;
            _mouseDownEvent.mode = mode;
            dispatchEvent(_mouseDownEvent);
        }
    }

    function pointerMove(pointer : Dynamic) {
        var axis = this.axis;
        var mode = this.mode;
        var object = this.object;
        var space = this.space;

        if (mode == "scale") {
            space = "local";
        } else if (axis == "E" || axis == "XYZE" || axis == "XYZ") {
            space = "world";
        }

        if (object == null || axis == null || !dragging || (pointer != null && pointer.button != -1)) return;

        if (pointer != null) _raycaster.setFromCamera(pointer, camera);

        var planeIntersect = intersectObjectWithRay(_plane, _raycaster, true);

        if (!planeIntersect) return;

        pointEnd.copy(planeIntersect.point).sub(worldPositionStart);

        if (mode == "translate") {
            _offset.copy(pointEnd).sub(pointStart);

            if (space == "local" && axis != "XYZ") {
                _offset.applyQuaternion(_worldQuaternionInv);
            }

            if (axis.indexOf("X") == -1) _offset.x = 0;
            if (axis.indexOf("Y") == -1) _offset.y = 0;
            if (axis.indexOf("Z") == -1) _offset.z = 0;

            if (space == "local" && axis != "XYZ") {
                _offset.applyQuaternion(_quaternionStart).divide(_parentScale);
            } else {
                _offset.applyQuaternion(_parentQuaternionInv).divide(_parentScale);
            }

            object.position.copy(_offset).add(_positionStart);

            if (translationSnap) {
                if (space == "local") {
                    object.position.applyQuaternion(_tempQuaternion.copy(_quaternionStart).invert());

                    if (axis.search("X") != -1) {
                        object.position.x = Std.int(object.position.x / translationSnap) * translationSnap;
                    }

                    if (axis.search("Y") != -1) {
                        object.position.y = Std.int(object.position.y / translationSnap) * translationSnap;
                    }

                    if (axis.search("Z") != -1) {
                        object.position.z = Std.int(object.position.z / translationSnap) * translationSnap;
                    }

                    object.position.applyQuaternion(_quaternionStart);
                }

                if (space == "world") {
                    if (object.parent) {
                        object.position.add(_tempVector.setFromMatrixPosition(object.parent.matrixWorld));
                    }

                    if (axis.search("X") != -1) {
                        object.position.x = Std.int(object.position.x / translationSnap) * translationSnap;
                    }

                    if (axis.search("Y") != -1) {
                        object.position.y = Std.int(object.position.y / translationSnap) * translationSnap;
                    }

                    if (axis.search("Z") != -1) {
                        object.position.z = Std.int(object.position.z / translationSnap) * translationSnap;
                    }

                    if (object.parent) {
                        object.position.sub(_tempVector.setFromMatrixPosition(object.parent.matrixWorld));
                    }
                }
            }
        } else if (mode == "scale") {
            if (axis.search("XYZ") != -1) {
                var d = pointEnd.length() / pointStart.length();

                if (pointEnd.dot(pointStart) < 0) d *= -1;

                _tempVector2.set(d, d, d);
            } else {
                _tempVector.copy(pointStart);
                _tempVector2.copy(pointEnd);

                _tempVector.applyQuaternion(_worldQuaternionInv);
                _tempVector2.applyQuaternion(_worldQuaternionInv);

                _tempVector2.divide(_tempVector);

                if (axis.search("X") == -1) {
                    _tempVector2.x = 1;
                }

                if (axis.search("Y") == -1) {
                    _tempVector2.y = 1;
                }

                if (axis.search("Z") == -1) {
                    _tempVector2.z = 1;
                }
            }

            object.scale.copy(_scaleStart).multiply(_tempVector2);

            if (scaleSnap) {
                if (axis.search("X") != -1) {
                    object.scale.x = Std.int(object.scale.x / scaleSnap) * scaleSnap || scaleSnap;
                }

                if (axis.search("Y") != -1) {
                    object.scale.y = Std.int(object.scale.y / scaleSnap) * scaleSnap || scaleSnap;
                }

                if (axis.search("Z") != -1) {
                    object.scale.z = Std.int(object.scale.z / scaleSnap) * scaleSnap || scaleSnap;
                }
            }
        } else if (mode == "rotate") {
            _offset.copy(pointEnd).sub(pointStart);

            var ROTATION_SPEED = 20 / worldPosition.distanceTo(_tempVector.setFromMatrixPosition(camera.matrixWorld));

            var _inPlaneRotation = false;

            if (axis == "XYZE") {
                rotationAxis.copy(_offset).cross(eye).normalize();
                rotationAngle = _offset.dot(_tempVector.copy(rotationAxis).cross(eye)) * ROTATION_SPEED;
            } else if (axis == "X" || axis == "Y" || axis == "Z") {
                rotationAxis.copy(_unit[axis]);

                _tempVector.copy(_unit[axis]);

                if (space == "local") {
                    _tempVector.applyQuaternion(worldQuaternion);
                }

                _tempVector.cross(eye);

                if (_tempVector.length() == 0) {
                    _inPlaneRotation = true;
                } else {
                    rotationAngle = _offset.dot(_tempVector.normalize()) * ROTATION_SPEED;
                }
            }

            if (axis == "E" || _inPlaneRotation) {
                rotationAxis.copy(eye);
                rotationAngle = pointEnd.angleTo(pointStart);

                _startNorm.copy(pointStart).normalize();
                _endNorm.copy(pointEnd).normalize();

                rotationAngle *= (_endNorm.cross(_startNorm).dot(eye) < 0 ? 1 : -1);
            }

            if (rotationSnap) rotationAngle = Std.int(rotationAngle / rotationSnap) * rotationSnap;

            if (space == "local" && axis != "E" && axis != "XYZE") {
                object.quaternion.copy(_quaternionStart);
                object.quaternion.multiply(_tempQuaternion.setFromAxisAngle(rotationAxis, rotationAngle)).normalize();
            } else {
                rotationAxis.applyQuaternion(_parentQuaternionInv);
                object.quaternion.copy(_tempQuaternion.setFromAxisAngle(rotationAxis, rotationAngle));
                object.quaternion.multiply(_quaternionStart).normalize();
            }
        }

        dispatchEvent(_changeEvent);
        dispatchEvent(_objectChangeEvent);
    }

    function pointerUp(pointer : Dynamic) {
        if (pointer != null && pointer.button != 0) return;

        if (dragging && (axis != null)) {
            _mouseUpEvent.mode = mode;
            dispatchEvent(_mouseUpEvent);
        }

        dragging = false;
        axis = null;
    }

    function dispose() {
        domElement.removeEventListener("pointerdown", _onPointerDown);
        domElement.removeEventListener("pointermove", _onPointerHover);
        domElement.removeEventListener("pointermove", _onPointerMove);
        domElement.removeEventListener("pointerup", _onPointerUp);

        traverse(function(child) {
            if (child.geometry) child.geometry.dispose();
            if (child.material) child.material.dispose();
        });
    }

    function attach(object : Object3D) {
        this.object = object;
        visible = true;
        return this;
    }

    function detach() {
        object = null;
        visible = false;
        axis = null;
        return this;
    }

    function reset() {
        if (!enabled) return;

        if (dragging) {
            object.position.copy(_positionStart);
            object.quaternion.copy(_quaternionStart);
            object.scale.copy(_scaleStart);

            dispatchEvent(_changeEvent);
            dispatchEvent(_objectChangeEvent);

            pointStart.copy(pointEnd);
        }
    }

    function getRaycaster() {
        return _raycaster;
    }

    function getMode() {
        return mode;
    }

    function setMode(mode : String) {
        this.mode = mode;
    }

    function setTranslationSnap(translationSnap : Float) {
        this.translationSnap = translationSnap;
    }

    function setRotationSnap(rotationSnap : Float) {
        this.rotationSnap = rotationSnap;
    }

    function setScaleSnap(scaleSnap : Float) {
        this.scaleSnap = scaleSnap;
    }

    function setSize(size : Float) {
        this.size = size;
    }

    function setSpace(space : String) {
        this.space = space;
    }
}

function getPointer(event : Event) {
    if (domElement.ownerDocument.pointerLockElement) {
        return {
            x: 0,
            y: 0,
            button: event.button
        };
    } else {
        var rect = domElement.getBoundingClientRect();
        return {
            x: (event.clientX - rect.left) / rect.width * 2 - 1,
            y: -(event.clientY - rect.top) / rect.height * 2 + 1,
            button: event.button
        };
    }
}

function onPointerHover(event : Event) {
    if (!enabled) return;

    switch (event.pointerType) {
        case "mouse":
        case "pen":
            pointerHover(_getPointer(event));
            break;
    }
}

function onPointerDown(event : Event) {
    if (!enabled) return;

    if (!document.pointerLockElement) {
        domElement.setPointerCapture(event.pointerId);
    }

    domElement.addEventListener("pointer