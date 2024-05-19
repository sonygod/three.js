// Haxe code

import js.three.cameras.PerspectiveCamera;

class ArrayCamera extends PerspectiveCamera {
    public var isArrayCamera:Bool;
    public var cameras:Array<PerspectiveCamera>;

    public function new(array:Array<PerspectiveCamera> = null) {
        super();

        isArrayCamera = true;
        cameras = array != null ? array : [];
    }
}

// no export statement in Haxe, use import statement to reference the class