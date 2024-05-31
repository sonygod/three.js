package ;

import three.MOUSE;
import three.TOUCH;
import three.examples.controls.OrbitControls;

/**
 * MapControls performs orbiting, dollying (zooming), and panning.
 * Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
 *
 *    Orbit - right mouse, or left mouse + ctrl/meta/shiftKey / touch: two-finger rotate
 *    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
 *    Pan - left mouse, or arrow keys / touch: one-finger move
 */
class MapControls extends OrbitControls {

    public function new(object:Dynamic, domElement:Dynamic) {
        super(object, domElement);

        this.screenSpacePanning = false; // pan orthogonal to world-space direction camera.up

        this.mouseButtons.set(MOUSE.LEFT, MOUSE.PAN);
        this.mouseButtons.set(MOUSE.MIDDLE, MOUSE.DOLLY);
        this.mouseButtons.set(MOUSE.RIGHT, MOUSE.ROTATE);

        this.touches.set(TOUCH.ONE, TOUCH.PAN);
        this.touches.set(TOUCH.TWO, TOUCH.DOLLY_ROTATE);
    }
}