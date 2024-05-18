package three.js.examples.javascript.interactive;

import three.Group;
import three.Raycaster;
import three.Vector2;

class InteractiveGroup extends Group {
    private var _pointer:Vector2 = new Vector2();
    private var _event = { type: '', data: _pointer };
    private var _raycaster:Raycaster = new Raycaster();

    public function new() {
        super();
    }

    public function listenToPointerEvents(renderer:ThreeRenderer, camera:Camera) {
        var scope:InteractiveGroup = this;
        var raycaster:Raycaster = new Raycaster();
        var element:HtmlDom = renderer.domElement;

        function onPointerEvent(event:MouseEvent) {
            event.stopPropagation();

            var rect = element.getBoundingClientRect();
            _pointer.x = (event.clientX - rect.left) / rect.width * 2 - 1;
            _pointer.y = -(event.clientY - rect.top) / rect.height * 2 + 1;

            raycaster.setFromCamera(_pointer, camera);

            var intersects:Array<RaycastHit> = raycaster.intersectObjects(this.children, false);

            if (intersects.length > 0) {
                var intersection:RaycastHit = intersects[0];
                var object:Object3D = intersection.object;
                var uv:Vector2 = intersection.uv;

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

    public function listenToXRControllerEvents(controller:Object) {
        var scope:InteractiveGroup = this;

        // TODO: Dispatch pointerevents too
        var events:Map<String, String> = [
            'move' => 'mousemove',
            'select' => 'click',
            'selectstart' => 'mousedown',
            'selectend' => 'mouseup'
        ];

        function onXRControllerEvent(event:Event) {
            var controller:Object = event.target;

            _raycaster.setFromXRController(controller);

            var intersections:Array<RaycastHit> = _raycaster.intersectObjects(this.children, false);

            if (intersections.length > 0) {
                var intersection:RaycastHit = intersections[0];
                var object:Object3D = intersection.object;
                var uv:Vector2 = intersection.uv;

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

extern class ThreeRenderer {
    public var domElement:HtmlDom;
}

extern class Camera {
    public function new() {}
}

extern class HtmlDom {
    public function getBoundingClientRect():Rectangle;
}

extern class Rectangle {
    public var left:Float;
    public var top:Float;
    public var width:Float;
    public var height:Float;
}

extern class MouseEvent {
    public var clientX:Float;
    public var clientY:Float;
    public var type:String;
    public function stopPropagation():Void;
}

extern class Event {
    public var target:Object;
    public var type:String;
}

extern class Object3D {
    public function dispatchEvent(event:Dynamic):Void;
}

extern class RaycastHit {
    public var object:Object3D;
    public var uv:Vector2;
}