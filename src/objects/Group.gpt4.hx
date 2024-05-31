package objects;

import core.Object3D;

class Group extends Object3D {
    
    public var isGroup:Bool;
    
    public function new() {
        super();
        isGroup = true;
        type = "Group";
    }
    
}