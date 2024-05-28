package three.js.src.cameras;

import three.js.src.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {

    public var isArrayCamera:Bool = true;
    public var cameras:Array<Dynamic>;

    public function new(?array:Array<Dynamic>) {
        super();
        this.cameras = array != null ? array : [];
    }

}