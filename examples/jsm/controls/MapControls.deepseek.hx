import three.js.examples.jsm.controls.OrbitControls;

class MapControls extends OrbitControls {

    public function new(object:Dynamic, domElement:Dynamic) {
        super(object, domElement);

        this.screenSpacePanning = false; // pan orthogonal to world-space direction camera.up

        this.mouseButtons = { LEFT: MOUSE.PAN, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.ROTATE };

        this.touches = { ONE: TOUCH.PAN, TWO: TOUCH.DOLLY_ROTATE };
    }

}

typedef MOUSE = {
    var PAN:Int;
    var ROTATE:Int;
    var DOLLY:Int;
}

typedef TOUCH = {
    var PAN:Int;
    var DOLLY_ROTATE:Int;
}

class MOUSE {
    public static var PAN:Int = 0;
    public static var ROTATE:Int = 1;
    public static var DOLLY:Int = 2;
}

class TOUCH {
    public static var PAN:Int = 0;
    public static var DOLLY_ROTATE:Int = 1;
}