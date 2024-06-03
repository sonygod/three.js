import Command;
import Vector3; // assuming this is defined

class SetScaleCommand extends Command {
    public var type: String;
    public var name: String;
    public var updatable: Bool;
    public var object: Object3D;
    public var oldScale: Vector3;
    public var newScale: Vector3;

    public function new(editor: Editor, ?object: Object3D, ?newScale: Vector3, ?optionalOldScale: Vector3) {
        super(editor);

        this.type = 'SetScaleCommand';
        this.name = editor.strings.getKey('command/SetScale');
        this.updatable = true;

        this.object = object != null ? object : null;

        if (this.object != null && newScale != null) {
            this.oldScale = this.object.scale.clone();
            this.newScale = newScale.clone();
        }

        if (optionalOldScale != null) {
            this.oldScale = optionalOldScale.clone();
        }
    }

    public function execute(): Void {
        this.object.scale.copy(this.newScale);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function undo(): Void {
        this.object.scale.copy(this.oldScale);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function update(command: SetScaleCommand): Void {
        this.newScale.copy(command.newScale);
    }

    public function toJSON(): Dynamic {
        var output: Dynamic = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.oldScale = this.oldScale.toArray();
        output.newScale = this.newScale.toArray();

        return output;
    }

    public function fromJSON(json: Dynamic): Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.oldScale = new Vector3().fromArray(json.oldScale);
        this.newScale = new Vector3().fromArray(json.newScale);
    }
}