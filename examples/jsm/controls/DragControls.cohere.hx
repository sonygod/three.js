package;

import js.three.EventDispatcher;
import js.three.Matrix4;
import js.three.Plane;
import js.three.Raycaster;
import js.three.Vector2;
import js.three.Vector3;

class DragControls extends EventDispatcher {
    private var _plane:Plane;
    private var _raycaster:Raycaster;
    private var _pointer:Vector2;
    private var _offset:Vector3;
    private var _diff:Vector2;
    private var _previousPointer:Vector2;
    private var _intersection:Vector3;
    private var _worldPosition:Vector3;
    private var _inverseMatrix:Matrix4;
    private var _up:Vector3;
    private var _right:Vector3;
    private var _objects:Array;
    private var _camera:Dynamic;
    private var _domElement:Dynamic;
    private var _selected:Dynamic;
    private var _hovered:Dynamic;
    private var _intersections:Array<Dynamic>;
    private var _scope:DragControls;

    public var mode:String;
    public var rotateSpeed:Float;
    public var enabled:Bool;
    public var recursive:Bool;
    public var transformGroup:Bool;

    public function new(_objects:Array, _camera:Dynamic, _domElement:Dynamic) {
        super();
        _domElement.style.touchAction = 'none';
        _selected = null;
        _hovered = null;
        _intersections = [];
        mode = 'translate';
        rotateSpeed = 1;
        _scope = this;
        activate();

        function activate() {
            _domElement.addEventListener('pointermove', onPointerMove);
            _domElement.addEventListener('pointerdown', onPointerDown);
            _domElement.addEventListener('pointerup', onPointerCancel);
            _domElement.addEventListener('pointerleave', onPointerCancel);
        }

        function deactivate() {
            _domElement.removeEventListener('pointermove', onPointerMove);
            _domElement.removeEventListener('pointerdown', onPointerDown);
            _domElement.removeEventListener('pointerup', onPointerCancel);
            _domElement.removeEventListener('pointerleave', onPointerCancel);
            _domElement.style.cursor = '';
        }

        function dispose() {
            deactivate();
        }

        function getObjects():Array {
            return _objects;
        }

        function setObjects(objects:Array) {
            _objects = objects;
        }

        function getRaycaster():Raycaster {
            return _raycaster;
        }

        function onPointerMove(event:Dynamic) {
            if (!enabled) return;
            updatePointer(event);
            _raycaster.setFromCamera(_pointer, _camera);
            if (_selected != null) {
                if (mode == 'translate') {
                    if (_raycaster.ray.intersectPlane(_plane, _intersection)) {
                        _selected.position.copy(_intersection.sub(_offset).applyMatrix4(_inverseMatrix));
                    }
                } else if (mode == 'rotate') {
                    _diff.subVectors(_pointer, _previousPointer).multiplyScalar(rotateSpeed);
                    _selected.rotateOnWorldAxis(_up, _diff.x);
                    _selected.rotateOnWorldAxis(_right.normalize(), -_diff.y);
                }
                dispatchEvent({ type: 'drag', object: _selected });
                _previousPointer.copy(_pointer);
            } else {
                // hover support
                if (event.pointerType == 'mouse' || event.pointerType == 'pen') {
                    _intersections.length = 0;
                    _raycaster.setFromCamera(_pointer, _camera);
                    _raycaster.intersectObjects(_objects, recursive, _intersections);
                    if (_intersections.length > 0) {
                        var object = _intersections[0].object;
                        _plane.setFromNormalAndCoplanarPoint(_camera.getWorldDirection(_plane.normal), _worldPosition.setFromMatrixPosition(object.matrixWorld));
                        if (_hovered != object && _hovered != null) {
                            dispatchEvent({ type: 'hoveroff', object: _hovered });
                            _domElement.style.cursor = 'auto';
                            _hovered = null;
                        }
                        if (_hovered != object) {
                            dispatchEvent({ type: 'hoveron', object: object });
                            _domElement.style.cursor = 'pointer';
                            _hovered = object;
                        }
                    } else {
                        if (_hovered != null) {
                            dispatchEvent({ type: 'hoveroff', object: _hovered });
                            _domElement.style.cursor = 'auto';
                            _hovered = null;
                        }
                    }
                }
            }
            _previousPointer.copy(_pointer);
        }

        function onPointerDown(event:Dynamic) {
            if (!enabled) return;
            updatePointer(event);
            _intersections.length = 0;
            _raycaster.setFromCamera(_pointer, _camera);
            _raycaster.intersectObjects(_objects, recursive, _intersections);
            if (_intersections.length > 0) {
                if (transformGroup) {
                    // look for the outermost group in the object's upper hierarchy
                    _selected = findGroup(_intersections[0].object);
                } else {
                    _selected = _intersections[0].object;
                }
                _plane.setFromNormalAndCoplanarPoint(_camera.getWorldDirection(_plane.normal), _worldPosition.setFromMatrixPosition(_selected.matrixWorld));
                if (_raycaster.ray.intersectPlane(_plane, _intersection)) {
                    if (mode == 'translate') {
                        _inverseMatrix.copy(_selected.parent.matrixWorld).invert();
                        _offset.copy(_intersection).sub(_worldPosition.setFromMatrixPosition(_selected.matrixWorld));
                    } else if (mode == 'rotate') {
                        // the controls only support Y+ up
                        _up.set(0, 1, 0).applyQuaternion(_camera.quaternion).normalize();
                        _right.set(1, 0, 0).applyQuaternion(_camera.quaternion).normalize();
                    }
                }
                _domElement.style.cursor = 'move';
                dispatchEvent({ type: 'dragstart', object: _selected });
            }
            _previousPointer.copy(_pointer);
        }

        function onPointerCancel() {
            if (!enabled) return;
            if (_selected != null) {
                dispatchEvent({ type: 'dragend', object: _selected });
                _selected = null;
            }
            _domElement.style.cursor = _hovered ? 'pointer' : 'auto';
        }

        function updatePointer(event:Dynamic) {
            var rect = _domElement.getBoundingClientRect();
            _pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
            _pointer.y = - (event.clientY - rect.top) / rect.height * 2 + 1;
        }

        function findGroup(obj:Dynamic, group:Dynamic = null):Dynamic {
            if (obj.isGroup) group = obj;
            if (obj.parent == null) return group;
            return findGroup(obj.parent, group);
        }
    }
}