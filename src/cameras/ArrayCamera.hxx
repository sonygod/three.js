import three.js.src.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {

    public var isArrayCamera:Bool;
    public var cameras(default, null):Array<PerspectiveCamera>;

    public function new(array:Array<PerspectiveCamera> = []) {
        super();
        this.isArrayCamera = true;
        this.cameras = array;
    }

}

typedef ArrayCamera_three_js_src_cameras_ArrayCamera = ArrayCamera;