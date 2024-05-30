package three.js.editor.commands;

import three.js.editor.Command;
import three.Vector3;

class SetScaleCommand extends Command {
    public var object : three.Object3D;
    public var oldScale : Vector3;
    public var newScale : Vector3;

    public function new(editor : Editor, object = null, newScale = null, optionalOldScale = null) {
        super(editor);

        this.type = 'SetScaleCommand';
        this.name = editor.getString('command/SetScale');
        this.updatable = true;

        this.object = object;

        if (object != null && newScale != null) {
            this.oldScale = object.scale.clone();
            this.newScale = newScale.clone();
        }

        if (optionalOldScale != null) {
            this.oldScale = optionalOldScale.clone();
        }
    }

    public function execute() {
        object.scale.copy(newScale);
        object.updateMatrixWorld(true);
        editor.signals.objectChanged.dispatch(object);
    }

    public function undo() {
        object.scale.copy(oldScale);
        object.updateMatrixWorld(true);
        editor.signals.objectChanged.dispatch(object);
    }

    public function update(command : SetScaleCommand) {
        newScale.copy(command.newScale);
    }

    public function toJSON() : Dynamic {
        var output : Dynamic = super.toJSON(this);
        output.objectUuid = object.uuid;
        output.oldScale = oldScale.toArray();
        output.newScale = newScale.toArray();
        return output;
    }

    public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);
        object = editor.getObjectByUuid(json.objectUuid);
        oldScale = new Vector3().fromArray(json.oldScale);
        newScale = new Vector3().fromArray(json.newScale);
    }
}