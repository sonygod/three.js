import haxe.Timer;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.MouseEvent;
import three.EventDispatcher;
import three.Matrix4;
import three.Plane;
import three.Raycaster;
import three.Vector2;
import three.Vector3;

class DragControls extends EventDispatcher {
    private var _objects:Array<three.Object3D>;
    private var _camera:three.Camera;
    private var _domElement:Element;
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
    private var _selected:three.Object3D;
    private var _hovered:three.Object3D;
    private var _intersections:Array<RaycastResult>;
    private var _enabled:Bool;
    private var _recursive:Bool;
    private var _transformGroup:Bool;
    private var _mode:String;

    public function new(objects:Array<three.Object3D>, camera:three.Camera, domElement:Element) {
        super();
        _objects = objects;
        _camera = camera;
        _domElement = domElement;
        _plane = new Plane();
        _raycaster = new Raycaster();
        _pointer = new Vector2();
        _offset = new Vector3();
        _diff = new Vector2();
        _previousPointer = new Vector2();
        _intersection = new Vector3();
        _worldPosition = new Vector3();
        _inverseMatrix = new Matrix4();
        _up = new Vector3();
        _right = new Vector3();
        _selected = null;
        _hovered = null;
        _intersections = [];
        _enabled = true;
        _recursive = true;
        _transformGroup = false;
        _mode = 'translate';

        activate();
    }

    private function activate():Void {
        _domElement.addEventListener('pointermove', onPointerMove);
        _domElement.addEventListener('pointerdown', onPointerDown);
        _domElement.addEventListener('pointerup', onPointerCancel);
        _domElement.addEventListener('pointerleave', onPointerCancel);
    }

    private function deactivate():Void {
        _domElement.removeEventListener('pointermove', onPointerMove);
        _domElement.removeEventListener('pointerdown', onPointerDown);
        _domElement.removeEventListener('pointerup', onPointerCancel);
        _domElement.removeEventListener('pointerleave', onPointerCancel);
        _domElement.style.cursor = '';
    }

    private function dispose():Void {
        deactivate();
    }

    private function getObjects():Array<three.Object3D> {
        return _objects;
    }

    private function setObjects(objects:Array<three.Object3D>):Void {
        _objects = objects;
    }

    private function getRaycaster():Raycaster {
        return _raycaster;
    }

    private function onPointerMove(event:MouseEvent):Void {
        if (!_enabled) return;
        updatePointer(event);
        _raycaster.setFromCamera(_pointer, _camera);
        if (_selected != null) {
            if (_mode == 'translate') {
                if (_raycaster.ray.intersectPlane(_plane, _intersection)) {
                    _selected.position.copy(_intersection.sub(_offset).applyMatrix4(_inverseMatrix));
                }
            } else if (_mode == 'rotate') {
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
                _raycaster.intersectObjects(_objects, _recursive, _intersections);
                if (_intersections.length > 0) {
                    var object:three.Object3D = _intersections[0].object;
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
            _previousPointer.copy(_pointer);
        }
    }

    private function onPointerDown(event:MouseEvent):Void {
        if (!_enabled) return;
        updatePointer(event);
        _intersections.length = 0;
        _raycaster.setFromCamera(_pointer, _camera);
        _raycaster.intersectObjects(_objects, _recursive, _intersections);
        if (_intersections.length > 0) {
            if (_transformGroup) {
                _selected = findGroup(_intersections[0].object);
            } else {
                _selected = _intersections[0].object;
            }
            _plane.setFromNormalAndCoplanarPoint(_camera.getWorldDirection(_plane.normal), _worldPosition.setFromMatrixPosition(_selected.matrixWorld));
            if (_raycaster.ray.intersectPlane(_plane, _intersection)) {
                if (_mode == 'translate') {
                    _inverseMatrix.copy(_selected.parent.matrixWorld).invert();
                    _offset.copy(_intersection).sub(_worldPosition.setFromMatrixPosition(_selected.matrixWorld));
                } else if (_mode == 'rotate') {
                    _up.set(0, 1, 0).applyQuaternion(_camera.quaternion).normalize();
                    _right.set(1, 0, 0).applyQuaternion(_camera.quaternion).normalize();
                }
            }
            _domElement.style.cursor = 'move';
            dispatchEvent({ type: 'dragstart', object: _selected });
        }
    }

    private function onPointerCancel():Void {
        if (!_enabled) return;
        if (_selected != null) {
            dispatchEvent({ type: 'dragend', object: _selected });
            _selected = null;
        }
        _domElement.style.cursor = _hovered != null ? 'pointer' : 'auto';
    }

    private function updatePointer(event:MouseEvent):Void {
        var rect = _domElement.getBoundingClientRect();
        _pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
        _pointer.y = - (event.clientY - rect.top) / rect.height * 2 + 1;
    }

    private function findGroup(obj:three.Object3D, group:three.Group = null):three.Group {
        if (obj.isGroup) group = obj;
        if (obj.parent == null) return group;
        return findGroup(obj.parent, group);
    }

    public function activate():Void {
        activate();
    }

    public function deactivate():Void {
        deactivate();
    }

    public function dispose():Void {
        dispose();
    }

    public function getObjects():Array<three.Object3D> {
        return getObjects();
    }

    public function getRaycaster():Raycaster {
        return getRaycaster();
    }

    public function setObjects(objects:Array<three.Object3D>):Void {
        setObjects(objects);
    }
}