package three.js.editor.js.commands;

import three.js.editor.js.Command;
import three.js.Vector3;

class SetPositionCommand extends Command {
    public var object : threewise.Object3D;
    public var oldPosition : Vector3;
    public var newPosition : Vector3;

    public function new(editor : Editor, object : threewise.Object3D = null, newPosition : Vector3 = null, optionalOldPosition : Vector3 = null) {
        super(editor);

        this.type = 'SetPositionCommand';
        this.name = editor.getString('command/SetPosition');
        this.updatable = true;

        this.object = object;

        if (object != null && newPosition != null) {
            this.oldPosition = object.position.clone();
            this.newPosition = newPosition.clone();
        }

        if (optionalOldPosition != null) {
            this.oldPosition = optionalOldPosition.clone();
        }
    }

    public function execute() : Void {
        object.position.copy(newPosition);
        object.updateMatrixWorld(true);
        editor.signals.objectChanged.dispatch(object);
    }

    public function undo() : Void {
        object.position.copy(oldPosition);
        object.updateMatrixWorld(true);
        editor.signals.objectChanged.dispatch(object);
    }

    public function update(command : SetPositionCommand) : Void {
        newPosition.copy(command.newPosition);
    }

    public function toJSON() : Dynamic {
        var output : Dynamic = super.toJSON();

        output.objectUuid = object.uuid;
        output.oldPosition = oldPosition.toArray();
        output.newPosition = newPosition.toArray();

        return output;
    }

    public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);

        object = editor.objectByUuid(json.objectUuid);
        oldPosition = new Vector3().fromArray(json.oldPosition);
        newPosition = new Vector3().fromArray(json.newPosition);
    }
}