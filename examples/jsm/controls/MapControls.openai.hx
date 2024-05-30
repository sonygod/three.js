package three.js.examples.jsm.controls;

import three.M MOUSE;
import three.M TOUCH;

class MapControls extends OrbitControls {
    
    public function new(object:Object3D, domElement:js.html.Element) {
        super(object, domElement);

        screenSpacePanning = false; // pan orthogonal to world-space direction camera.up

        mouseButtons = {
            LEFT: MOUSE.PAN,
            MIDDLE: MOUSE.DOLLY,
            RIGHT: MOUSE.ROTATE
        };

        touches = {
            ONE: TOUCH.PAN,
            TWO: TOUCH.DOLLY_ROTATE
        };
    }
}