import three.js.editor.js.commands.Command;
import three.Vector3;

class SetScaleCommand extends Command {

	public function new(editor:Editor, object:three.Object3D = null, newScale:Vector3 = null, optionalOldScale:Vector3 = null) {
		super(editor);

		this.type = 'SetScaleCommand';
		this.name = editor.strings.getKey('command/SetScale');
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
		this.object.scale.copy(this.newScale);
		this.object.updateMatrixWorld(true);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	public function undo() {
		this.object.scale.copy(this.oldScale);
		this.object.updateMatrixWorld(true);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	public function update(command:SetScaleCommand) {
		this.newScale.copy(command.newScale);
	}

	public function toJSON() {
		var output = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.oldScale = this.oldScale.toArray();
		output.newScale = this.newScale.toArray();

		return output;
	}

	public function fromJSON(json:Dynamic) {
		super.fromJSON(json);

		this.object = this.editor.objectByUuid(json.objectUuid);
		this.oldScale = new Vector3().fromArray(json.oldScale);
		this.newScale = new Vector3().fromArray(json.newScale);
	}
}