package three.objects;

import three.core.Object3D;

class Group extends Object3D {

    public var isGroup:Bool = true;
    public var type:String = 'Group';

    public function new() {
        super();
    }

}