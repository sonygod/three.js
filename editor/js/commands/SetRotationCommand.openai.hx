package three.js.editor.commands;

import three.js.editor.Command;
import three.Euler;

class SetRotationCommand extends Command {
    public var object : three.Object3D;
    public var oldRotation : Euler;
    public var newRotation : Euler;

    public function new(editor : Editor, ?object : three.Object3D, ?newRotation : Euler, ?optionalOldRotation : Euler) {
        super(editor);

        this.type = 'SetRotationCommand';
        this.name = editor.strings.getKey('command/SetRotation');
        this.updatable = true;

        this.object = object;

        if (object != null && newRotation != null) {
            this.oldRotation = object.rotation.clone();
            this.newRotation = newRotation.clone();
        }

        if (optionalOldRotation != null) {
            this.oldRotation = optionalOldRotation.clone();
        }
    }

    public function execute() : Void {
        this.object.rotation.copy(this.newRotation);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function undo() : Void {
        this.object.rotation.copy(this.oldRotation);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function update(command : SetRotationCommand) : Void {
        this.newRotation.copy(command.newRotation);
    }

    public function toJSON() : Dynamic {
        var output = super.toJSON(this);
        output.objectUuid = this.object.uuid;
        output.oldRotation = this.oldRotation.toArray();
        output.newRotation = this.newRotation.toArray();
        return output;
    }

    public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);
        this.object = this.editor.objectByUuid(json.objectUuid);
        this.oldRotation = new Euler().fromArray(json.oldRotation);
        this.newRotation = new Euler().fromArray(json.newRotation);
    }
}