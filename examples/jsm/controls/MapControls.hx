package three.js.examples.jm.controls;

import three.MOUSE;
import three.TOUCH;

import OrbitControls from './OrbitControls';

// MapControls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - right mouse, or left mouse + ctrl/meta/shiftKey / touch: two-finger rotate
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - left mouse, or arrow keys / touch: one-finger move

class MapControls extends OrbitControls {

    public function new(object:Dynamic, domElement:Dynamic) {
        super(object, domElement);

        screenSpacePanning = false; // pan orthogonal to world-space direction camera.up

        mouseButtons = { LEFT: MOUSE.PAN, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.ROTATE };

        touches = { ONE: TOUCH.PAN, TWO: TOUCH.DOLLY_ROTATE };
    }

}

@:keep
@:expose("MapControls")
class __MapControls {
    public static function main() {}
}