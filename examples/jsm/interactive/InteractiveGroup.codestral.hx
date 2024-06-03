import three.Group;
import three.Raycaster;
import three.Vector2;
import three.Vector;
import three.events.EventDispatcher;

class InteractiveGroup extends Group {
    private var _pointer: Vector = new Vector2();
    private var _event: Dynamic = { type: '', data: _pointer };

    private var _raycaster: Raycaster = new Raycaster();

    public function listenToPointerEvents(renderer: Renderer, camera: Camera) {
        var scope: InteractiveGroup = this;
        var raycaster: Raycaster = new Raycaster();

        var element = renderer.domElement;

        function onPointerEvent(event: Dynamic) {
            event.stopPropagation();

            var rect = renderer.domElement.getBoundingClientRect();

            _pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
            _pointer.y = - (event.clientY - rect.top) / rect.height * 2 + 1;

            raycaster.setFromCamera(_pointer, camera);

            var intersects = raycaster.intersectObjects(scope.children, false);

            if (intersects.length > 0) {
                var intersection = intersects[0];

                var object: EventDispatcher = intersection.object;
                var uv = intersection.uv;

                _event.type = event.type;
                _event.data.set(uv.x, 1 - uv.y);

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

    public function listenToXRControllerEvents(controller: Dynamic) {
        var scope: InteractiveGroup = this;

        var events: Map<String, String> = new Map<String, String>();
        events.set('move', 'mousemove');
        events.set('select', 'click');
        events.set('selectstart', 'mousedown');
        events.set('selectend', 'mouseup');

        function onXRControllerEvent(event: Dynamic) {
            var controller = event.target;

            _raycaster.setFromXRController(controller);

            var intersections = _raycaster.intersectObjects(scope.children, false);

            if (intersections.length > 0) {
                var intersection = intersections[0];

                var object: EventDispatcher = intersection.object;
                var uv = intersection.uv;

                _event.type = events.get(event.type);
                _event.data.set(uv.x, 1 - uv.y);

                object.dispatchEvent(_event);
            }
        }

        controller.addEventListener('move', onXRControllerEvent);
        controller.addEventListener('select', onXRControllerEvent);
        controller.addEventListener('selectstart', onXRControllerEvent);
        controller.addEventListener('selectend', onXRControllerEvent);
    }
}