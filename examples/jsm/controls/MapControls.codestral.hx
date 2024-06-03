import three.MOUSE;
import three.TOUCH;
import three.controls.OrbitControls;

class MapControls extends OrbitControls {

    public function new(object:three.Object3D, domElement:Dynamic) {
        super(object, domElement);

        this.screenSpacePanning = false;

        this.mouseButtons = {
            LEFT: MOUSE.PAN,
            MIDDLE: MOUSE.DOLLY,
            RIGHT: MOUSE.ROTATE
        };

        this.touches = {
            ONE: TOUCH.PAN,
            TWO: TOUCH.DOLLY_ROTATE
        };
    }
}