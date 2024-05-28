import js.Browser.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {

    public var cameras(default, null):Array<PerspectiveCamera>;

    public function new(array:Array<PerspectiveCamera> = []) {
        super();
        this.isArrayCamera = true;
        this.cameras = array;
    }

}

typedef ArrayCameraJs = js.Browser.ArrayCamera;

@:native("ArrayCamera")
class ArrayCamera extends ArrayCameraJs {}