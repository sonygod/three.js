import three.js.src.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {

    public var isArrayCamera:Bool = true;
    public var cameras:Array<PerspectiveCamera>;

    public function new(array:Array<PerspectiveCamera> = []) {
        super();

        this.cameras = array;
    }

}

export haxe.macro.Expr.createClass("three.js.src.cameras", "ArrayCamera", [], ArrayCamera);