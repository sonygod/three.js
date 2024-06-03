import three.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {

    public function new(array:Array<PerspectiveCamera> = []) {
        super();

        this.isArrayCamera = true;
        this.cameras = array;
    }

    public var cameras(default, null):Array<PerspectiveCamera>;
    public var isArrayCamera(default, null):Bool;
}