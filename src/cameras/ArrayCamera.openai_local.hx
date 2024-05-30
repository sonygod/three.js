import three.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {

    public var isArrayCamera:Bool;
    public var cameras:Array<PerspectiveCamera>;

    public function new(array:Array<PerspectiveCamera> = []) {
        super();

        this.isArrayCamera = true;
        this.cameras = array;
    }

}