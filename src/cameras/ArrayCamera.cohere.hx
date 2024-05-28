class ArrayCamera extends PerspectiveCamera {
    public var isArrayCamera:Bool = true;
    public var cameras:Array<PerspectiveCamera>;

    public function new(array:Array<PerspectiveCamera> = []) {
        super();
        cameras = array;
    }
}