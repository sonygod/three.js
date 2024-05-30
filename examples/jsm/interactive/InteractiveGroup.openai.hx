package three.js.examples.jsm.interactive;

import three.Group;
import three.Raycaster;
import three.Vector2;

class InteractiveGroup extends Group {
    private var _pointer:Vector2 = new Vector2();
    private var _event:{ type:String, data:Vector2 } = { type:'', data:_pointer };
    private var _raycaster:Raycaster = new Raycaster();

    public function new() {
        super();
    }

    public function listenToPointerEvents(renderer:Dynamic, camera:Dynamic) {
        var scope:InteractiveGroup = this;
        var raycaster:Raycaster = new Raycaster();
        var element:Dynamic = renderer.domElement;

        function onPointerEvent(event:Dynamic) {
            event.stopPropagation();

            var rect:Dynamic = element.getBoundingClientRect();
            _pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
            _pointer.y = -(event.clientY - rect.top) / rect.height * 2 + 1;

            raycaster.setFromCamera(_pointer, camera);

            var intersects:Array<Dynamic> = raycaster.intersectObjects(scope.children, false);

            if (intersects.length > 0) {
                var intersection:Dynamic = intersects[0];
                var object:Dynamic = intersection.object;
                var uv:Dynamic = intersection.uv;

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

    public function listenToXRControllerEvents(controller:Dynamic) {
        var scope:InteractiveGroup = this;
        var events:Dynamic = {
            'move': 'mousemove',
            'select': 'click',
            'selectstart': 'mousedown',
            'selectend': 'mouseup'
        };

        function onXRControllerEvent(event:Dynamic) {
            var controller:Dynamic = event.target;

            _raycaster.setFromXRController(controller);

            var intersections:Array<Dynamic> = _raycaster.intersectObjects(scope.children, false);

            if (intersections.length > 0) {
                var intersection:Dynamic = intersections[0];
                var object:Dynamic = intersection.object;
                var uv:Dynamic = intersection.uv;

                _event.type = events[event.type];
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