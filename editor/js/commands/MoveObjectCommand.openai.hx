package threejs.editor.commands;

import threejs.editor.Command;

class MoveObjectCommand extends Command {
    public var object : THREE.Object3D;
    public var oldParent : THREE.Object3D;
    public var oldIndex : Int;
    public var newParent : THREE.Object3D;
    public var newIndex : Int;
    public var newBefore : THREE.Object3D;

    public function new(editor : Editor, object : THREE.Object3D = null, newParent : THREE.Object3D = null, newBefore : THREE.Object3D = null) {
        super(editor);

        this.type = 'MoveObjectCommand';
        this.name = editor.strings.getKey('command/MoveObject');

        this.object = object;
        this.oldParent = (object != null) ? object.parent : null;
        this.oldIndex = (this.oldParent != null) ? this.oldParent.children.indexOf(object) : null;
        this.newParent = newParent;

        if (newBefore != null) {
            this.newIndex = (newParent != null) ? newParent.children.indexOf(newBefore) : null;
        } else {
            this.newIndex = (newParent != null) ? newParent.children.length : null;
        }

        if (this.oldParent == this.newParent && this.newIndex > this.oldIndex) {
            this.newIndex--;
        }

        this.newBefore = newBefore;
    }

    override public function execute() {
        this.oldParent.remove(this.object);

        var children = this.newParent.children;
        children.splice(this.newIndex, 0, this.object);
        this.object.parent = this.newParent;

        this.object.dispatchEvent({ type: 'added' });
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    override public function undo() {
        this.newParent.remove(this.object);

        var children = this.oldParent.children;
        children.splice(this.oldIndex, 0, this.object);
        this.object.parent = this.oldParent;

        this.object.dispatchEvent({ type: 'added' });
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    override public function toJSON() {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.newParentUuid = this.newParent.uuid;
        output.oldParentUuid = this.oldParent.uuid;
        output.newIndex = this.newIndex;
        output.oldIndex = this.oldIndex;

        return output;
    }

    override public function fromJSON(json : Dynamic) {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.oldParent = this.editor.objectByUuid(json.oldParentUuid);
        if (this.oldParent == null) {
            this.oldParent = this.editor.scene;
        }

        this.newParent = this.editor.objectByUuid(json.newParentUuid);
        if (this.newParent == null) {
            this.newParent = this.editor.scene;
        }

        this.newIndex = json.newIndex;
        this.oldIndex = json.oldIndex;
    }
}