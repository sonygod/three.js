import three.core.Object3D;

class MoveObjectCommand extends Command {

    public var object:Object3D;
    public var oldParent:Object3D;
    public var oldIndex:Int;
    public var newParent:Object3D;
    public var newIndex:Int;
    public var newBefore:Object3D;

    public function new(editor:Editor, object:Object3D = null, newParent:Object3D = null, newBefore:Object3D = null) {
        super(editor);

        this.type = 'MoveObjectCommand';
        this.name = editor.strings.getKey('command/MoveObject');

        this.object = object;
        this.oldParent = (object != null) ? object.parent : null;
        this.oldIndex = (this.oldParent != null) ? this.oldParent.children.indexOf(this.object) : null;
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
        this.oldParent.remove(this.object);

        var children = this.newParent.children;
        children.insert(this.newIndex, this.object);
        this.object.parent = this.newParent;

        this.object.dispatchEvent({ type: 'added' });
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    override public function undo():Void {
        this.newParent.remove(this.object);

        var children = this.oldParent.children;
        children.insert(this.oldIndex, this.object);
        this.object.parent = this.oldParent;

        this.object.dispatchEvent({ type: 'added' });
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.newParentUuid = this.newParent.uuid;
        output.oldParentUuid = this.oldParent.uuid;
        output.newIndex = this.newIndex;
        output.oldIndex = this.oldIndex;

        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.object = cast this.editor.objectByUuid(json.objectUuid);
        this.oldParent = cast this.editor.objectByUuid(json.oldParentUuid);
        if (this.oldParent == null) {
            this.oldParent = this.editor.scene;
        }

        this.newParent = cast this.editor.objectByUuid(json.newParentUuid);
        if (this.newParent == null) {
            this.newParent = this.editor.scene;
        }

        this.newIndex = json.newIndex;
        this.oldIndex = json.oldIndex;
    }
}