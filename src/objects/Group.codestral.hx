import js.Object3D;

class Group extends Object3D {

    public function new() {
        super();
        this.isGroup = true;
        this.type = 'Group';
    }

}

export Group;