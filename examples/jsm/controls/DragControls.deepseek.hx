import three.EventDispatcher;
import three.Matrix4;
import three.Plane;
import three.Raycaster;
import three.Vector2;
import three.Vector3;

class DragControls extends EventDispatcher {

    var _plane:Plane;
    var _raycaster:Raycaster;

    var _pointer:Vector2;
    var _offset:Vector3;
    var _diff:Vector2;
    var _previousPointer:Vector2;
    var _intersection:Vector3;
    var _worldPosition:Vector3;
    var _inverseMatrix:Matrix4;

    var _up:Vector3;
    var _right:Vector3;

    var _objects:Array<Dynamic>;
    var _camera:Dynamic;
    var _domElement:Dynamic;

    var _selected:Dynamic;
    var _hovered:Dynamic;

    var _intersections:Array<Dynamic>;

    public var mode:String;
    public var rotateSpeed:Float;
    public var enabled:Bool;
    public var recursive:Bool;
    public var transformGroup:Bool;

    public function new(_objects:Array<Dynamic>, _camera:Dynamic, _domElement:Dynamic) {
        super();

        _domElement.style.touchAction = 'none'; // disable touch scroll

        _selected = null;
        _hovered = null;

        _intersections = [];

        mode = 'translate';

        rotateSpeed = 1;

        var scope = this;

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

        function getObjects():Array<Dynamic> {

            return _objects;

        }

        function setObjects(objects:Array<Dynamic>) {

            _objects = objects;

        }

        function getRaycaster():Raycaster {

            return _raycaster;

        }

        function onPointerMove(event:Dynamic) {

            if (scope.enabled === false) return;

            updatePointer(event);

            _raycaster.setFromCamera(_pointer, _camera);

            if (_selected) {

                if (scope.mode == 'translate') {

                    if (_raycaster.ray.intersectPlane(_plane, _intersection)) {

                        _selected.position.copy(_intersection.sub(_offset).applyMatrix4(_inverseMatrix));

                    }

                } else if (scope.mode == 'rotate') {

                    _diff.subVectors(_pointer, _previousPointer).multiplyScalar(scope.rotateSpeed);
                    _selected.rotateOnWorldAxis(_up, _diff.x);
                    _selected.rotateOnWorldAxis(_right.normalize(), - _diff.y);

                }

                scope.dispatchEvent({type: 'drag', object: _selected});

                _previousPointer.copy(_pointer);

            } else {

                // hover support

                if (event.pointerType == 'mouse' || event.pointerType == 'pen') {

                    _intersections.length = 0;

                    _raycaster.setFromCamera(_pointer, _camera);
                    _raycaster.intersectObjects(_objects, scope.recursive, _intersections);

                    if (_intersections.length > 0) {

                        var object = _intersections[0].object;

                        _plane.setFromNormalAndCoplanarPoint(_camera.getWorldDirection(_plane.normal), _worldPosition.setFromMatrixPosition(object.matrixWorld));

                        if (_hovered != object && _hovered != null) {

                            scope.dispatchEvent({type: 'hoveroff', object: _hovered});

                            _domElement.style.cursor = 'auto';
                            _hovered = null;

                        }

                        if (_hovered != object) {

                            scope.dispatchEvent({type: 'hoveron', object: object});

                            _domElement.style.cursor = 'pointer';
                            _hovered = object;

                        }

                    } else {

                        if (_hovered != null) {

                            scope.dispatchEvent({type: 'hoveroff', object: _hovered});

                            _domElement.style.cursor = 'auto';
                            _hovered = null;

                        }

                    }

                }

            }

            _previousPointer.copy(_pointer);

        }

        function onPointerDown(event:Dynamic) {

            if (scope.enabled === false) return;

            updatePointer(event);

            _intersections.length = 0;

            _raycaster.setFromCamera(_pointer, _camera);
            _raycaster.intersectObjects(_objects, scope.recursive, _intersections);

            if (_intersections.length > 0) {

                if (scope.transformGroup == true) {

                    // look for the outermost group in the object's upper hierarchy

                    _selected = findGroup(_intersections[0].object);

                } else {

                    _selected = _intersections[0].object;

                }

                _plane.setFromNormalAndCoplanarPoint(_camera.getWorldDirection(_plane.normal), _worldPosition.setFromMatrixPosition(_selected.matrixWorld));

                if (_raycaster.ray.intersectPlane(_plane, _intersection)) {

                    if (scope.mode == 'translate') {

                        _inverseMatrix.copy(_selected.parent.matrixWorld).invert();
                        _offset.copy(_intersection).sub(_worldPosition.setFromMatrixPosition(_selected.matrixWorld));

                    } else if (scope.mode == 'rotate') {

                        // the controls only support Y+ up
                        _up.set(0, 1, 0).applyQuaternion(_camera.quaternion).normalize();
                        _right.set(1, 0, 0).applyQuaternion(_camera.quaternion).normalize();

                    }

                }

                _domElement.style.cursor = 'move';

                scope.dispatchEvent({type: 'dragstart', object: _selected});

            }

            _previousPointer.copy(_pointer);

        }

        function onPointerCancel() {

            if (scope.enabled === false) return;

            if (_selected) {

                scope.dispatchEvent({type: 'dragend', object: _selected});

                _selected = null;

            }

            _domElement.style.cursor = _hovered ? 'pointer' : 'auto';

        }

        function updatePointer(event:Dynamic) {

            var rect = _domElement.getBoundingClientRect();

            _pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
            _pointer.y = -(event.clientY - rect.top) / rect.height * 2 + 1;

        }

        function findGroup(obj:Dynamic, group:Dynamic = null):Dynamic {

            if (obj.isGroup) group = obj;

            if (obj.parent == null) return group;

            return findGroup(obj.parent, group);

        }

        activate();

        // API

        this.enabled = true;
        this.recursive = true;
        this.transformGroup = false;

        this.activate = activate;
        this.deactivate = deactivate;
        this.dispose = dispose;
        this.getObjects = getObjects;
        this.getRaycaster = getRaycaster;
        this.setObjects = setObjects;

    }

}