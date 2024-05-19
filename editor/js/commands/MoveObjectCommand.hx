package three.js.editor.js.commands;

import three.js.editor.js.Command;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param newParent THREE.Object3D
 * @param newBefore THREE.Object3D
 */
class MoveObjectCommand extends Command {
    public var object:THREE.Object3D;
    public var oldParent:THREE.Object3D;
    public var oldIndex:Int;
    public var newParent:THREE.Object3D;
    public var newIndex:Int;
    public var newBefore:THREE.Object3D;

    public function new(editor:Editor, object:THREE.Object3D = null, newParent:THREE.Object3D = null, newBefore:THREE.Object3D = null) {
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

    override public function execute():Void {
        this.oldParent.remove(object);

        var children:Array<Dynamic> = this.newParent.children;
        children.splice(this.newIndex, 0, object);
        object.parent = this.newParent;

        object.dispatchEvent({ type: 'added' });
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function undo():Void {
        this.newParent.remove(object);

        var children:Array<Dynamic> = this.oldParent.children;
        children.splice(this.oldIndex, 0, object);
        object.parent = this.oldParent;

        object.dispatchEvent({ type: 'added' });
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function toJSON():Dynamic {
        var output:Dynamic = super.toJSON(this);

        output.objectUuid = object.uuid;
        output.newParentUuid = newParent.uuid;
        output.oldParentUuid = oldParent.uuid;
        output.newIndex = newIndex;
        output.oldIndex = oldIndex;

        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.object = editor.objectByUuid(json.objectUuid);
        this.oldParent = editor.objectByUuid(json.oldParentUuid);
        if (this.oldParent == null) {
            this.oldParent = editor.scene;
        }

        this.newParent = editor.objectByUuid(json.newParentUuid);

        if (this.newParent == null) {
            this.newParent = editor.scene;
        }

        this.newIndex = json.newIndex;
        this.oldIndex = json.oldIndex;
    }
}