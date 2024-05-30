import MOUSE.{PAN, DOLLY, ROTATE} from 'three';
import OrbitControls from './OrbitControls.js';

// MapControls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - right mouse, or left mouse + ctrl/meta/shiftKey / touch: two-finger rotate
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - left mouse, or arrow keys / touch: one-finger move

class MapControls extends OrbitControls {

	public var screenSpacePanning:Bool = false; // pan orthogonal to world-space direction camera.up

	public var mouseButtons:Map<String, Int> = { LEFT: PAN, MIDDLE: DOLLY, RIGHT: ROTATE };

	public var touches:Map<String, Int> = { ONE: TOUCH.PAN, TWO: TOUCH.DOLLY_ROTATE };

	public function new(object:Dynamic, domElement:Dynamic) {
		super(object, domElement);
	}

}

export MapControls;