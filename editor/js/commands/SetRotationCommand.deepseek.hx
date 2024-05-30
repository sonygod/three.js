import three.js.editor.js.commands.Command;
import three.Euler;

class SetRotationCommand extends Command {

	public function new(editor:Editor, object:three.Object3D = null, newRotation:three.Euler = null, optionalOldRotation:three.Euler = null) {
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

	public function execute() {
		this.object.rotation.copy(this.newRotation);
		this.object.updateMatrixWorld(true);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	public function undo() {
		this.object.rotation.copy(this.oldRotation);
		this.object.updateMatrixWorld(true);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	public function update(command:SetRotationCommand) {
		this.newRotation.copy(command.newRotation);
	}

	public function toJSON() {
		var output = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.oldRotation = this.oldRotation.toArray();
		output.newRotation = this.newRotation.toArray();

		return output;
	}

	public function fromJSON(json:Dynamic) {
		super.fromJSON(json);

		this.object = this.editor.objectByUuid(json.objectUuid);
		this.oldRotation = new Euler().fromArray(json.oldRotation);
		this.newRotation = new Euler().fromArray(json.newRotation);
	}
}