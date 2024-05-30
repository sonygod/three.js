import Command from '../Command.hx';

class MoveObjectCommand extends Command {
    public var object:Object3D;
    public var oldParent:Object3D;
    public var oldIndex:Int;
    public var newParent:Object3D;
    public var newIndex:Int;
    public var newBefore:Object3D;

    public function new(editor:Editor, ?object:Object3D, ?newParent:Object3D, ?newBefore:Object3D) {
        super(editor);
        $type = 'MoveObjectCommand';
        $name = editor.strings.getKey('command/MoveObject');

        $object = object;
        $oldParent = (object != null) ? object.parent : null;
        $oldIndex = (oldParent != null) ? oldParent.children.indexOf(object) : null;
        $newParent = newParent;

        if (newBefore != null) {
            $newIndex = (newParent != null) ? newParent.children.indexOf(newBefore) : null;
        } else {
            $newIndex = (newParent != null) ? newParent.children.length : null;
        }

        if (oldParent == newParent && newIndex > oldIndex) {
            newIndex--;
        }

        $newBefore = newBefore;
    }

    public function execute() {
        oldParent.remove(object);

        var children = newParent.children;
        children.splice(newIndex, 0, object);
        object.parent = newParent;

        object.dispatchEvent('added');
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo() {
        newParent.remove(object);

        var children = oldParent.children;
        children.splice(oldIndex, 0, object);
        object.parent = oldParent;

        object.dispatchEvent('added');
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Object {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.newParentUuid = newParent.uuid;
        output.oldParentUuid = oldParent.uuid;
        output.newIndex = newIndex;
        output.oldIndex = oldIndex;
        return output;
    }

    public function fromJSON(json:Object) {
        super.fromJSON(json);

        object = editor.objectByUuid(json.objectUuid);
        oldParent = editor.objectByUuid(json.oldParentUuid);
        if (oldParent == null) {
            oldParent = editor.scene;
        }

        newParent = editor.objectByUuid(json.newParentUuid);
        if (newParent == null) {
            newParent = editor.scene;
        }

        newIndex = json.newIndex;
        oldIndex = json.oldIndex;
    }
}

class Meta {
    public static function __register__() {
        var cls = MoveObjectCommand;
        #if js
        js.MoveObjectCommand = cls;
        #end
    }
}