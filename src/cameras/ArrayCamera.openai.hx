package three.cameras;

import three.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {
    public var isArrayCamera:Bool = true;
    public var cameras:Array<Dynamic>;

    public function new(?array:Array<Dynamic>) {
        super();
        cameras = array != null ? array : [];
    }
}