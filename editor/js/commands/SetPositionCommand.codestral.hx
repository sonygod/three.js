import Command from '../Command';
import Vector3 from 'three.js/Vector3';
import Editor from '../Editor';

class SetPositionCommand extends Command {

    var object: any;
    var oldPosition: Vector3;
    var newPosition: Vector3;

    public function new(editor: Editor, object: any = null, newPosition: Vector3 = null, optionalOldPosition: Vector3 = null) {
        super(editor);
        this.type = 'SetPositionCommand';
        this.name = editor.strings.getKey('command/SetPosition');
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

    public function execute(): Void {
        this.object.position.copy(this.newPosition);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function undo(): Void {
        this.object.position.copy(this.oldPosition);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function update(command: SetPositionCommand): Void {
        this.newPosition.copy(command.newPosition);
    }

    public function toJSON(): Dynamic {
        var output = super.toJSON();
        output.objectUuid = this.object.uuid;
        output.oldPosition = this.oldPosition.toArray();
        output.newPosition = this.newPosition.toArray();
        return output;
    }

    public function fromJSON(json: Dynamic): Void {
        super.fromJSON(json);
        this.object = this.editor.objectByUuid(json.objectUuid);
        this.oldPosition = new Vector3().fromArray(json.oldPosition);
        this.newPosition = new Vector3().fromArray(json.newPosition);
    }
}