import js.three.Mouse;
import js.three.OrbitControls;
import js.three.Touch;

class MapControls extends OrbitControls {
	public function new(object:Dynamic, domElement:Dynamic) {
		super(object, domElement);
		screenSpacePanning = false;
		mouseButtons = { LEFT: Mouse.PAN, MIDDLE: Mouse.DOLLY, RIGHT: Mouse.ROTATE };
		touches = { ONE: Touch.PAN, TWO: Touch.DOLLY_ROTATE };
	}
}

class Meta {
	public static var MapControls = { __name__: 'MapControls' };
}