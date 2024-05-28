import js.three.Group;
import js.three.Raycaster;
import js.three.Vector2;

class InteractiveGroup extends Group {
    static var _pointer:Vector2;
    static var _event:Dynamic;
    static var _raycaster:Raycaster;

    static function new() {
        super();
        _pointer = new Vector2();
        _event = { type: '', data: _pointer };
        _raycaster = new Raycaster();
    }

    public function listenToPointerEvents(renderer:Dynamic, camera:Dynamic) {
        var scope = this;
        var raycaster = new Raycaster();
        var element = renderer.domElement;

        function onPointerEvent(event:Dynamic) {
            event.stopPropagation();
            var rect = renderer.domElement.getBoundingClientRect();
            _pointer.x = (event.clientX - rect.left) / rect.width * 2.0 - 1.0;
            _pointer.y = - (event.clientY - rect.top) / rect.height * 2.0 + 1.0;
            raycaster.setFromCamera(_pointer, camera);
            var intersects = raycaster.intersectObjects(scope.children, false);
            if (intersects.length > 0) {
                var intersection = intersects[0];
                var object = intersection.object;
                var uv = intersection.uv;
                _event.type = event.type;
                _event.data.set(uv.x, 1.0 - uv.y);
                object.dispatchEvent(_event);
            }
        }

        element.addEventListener('pointerdown', onPointerEvent);
        element.addEventListener('pointerup', onPointerEvent);
        element.addEventListener('pointermove', onPointerEvent);
        element.addEventListener('mousedown', onPointerEvent);
        element.addEventListener('mouseup', onPointerEvent);
        element.addEventListener('mousemove', onPointerEvent);
        element.addEventListener('click', onPointerEvent);
    }

    public function listenToXRControllerEvents(controller:Dynamic) {
        var scope = this;
        var events = {
            'move': 'mousemove',
            'select': 'click',
            'selectstart': 'mousedown',
            'selectend': 'mouseup'
        };

        function onXRControllerEvent(event:Dynamic) {
            var controller = event.target;
            _raycaster.setFromXRController(controller);
            var intersections = _raycaster.intersectObjects(scope.children, false);
            if (intersections.length > 0) {
                var intersection = intersections[0];
                var object = intersection.object;
                var uv = intersection.uv;
                _event.type = events[event.type];
                _event.data.set(uv.x, 1.0 - uv.y);
                object.dispatchEvent(_event);
            }
        }

        controller.addEventListener('move', onXRControllerEvent);
        controller.addEventListener('select', onXRControllerEvent);
        controller.addEventListener('selectstart', onXRControllerEvent);
        controller.addEventListener('selectend', onXRControllerEvent);
    }
}

class Export {
    static function main() {
        var interactiveGroup = new InteractiveGroup();
    }
}