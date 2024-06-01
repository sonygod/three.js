import three.core.Object3D;
import three.math.Euler;

class SetRotationCommand extends Command {

	public var object:Object3D;
	public var oldRotation:Euler;
	public var newRotation:Euler;

	public function new(editor:Editor, object:Object3D = null, newRotation:Euler = null, optionalOldRotation:Euler = null) {

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

	override public function execute():Void {
		this.object.rotation.copy(this.newRotation);
		this.object.updateMatrixWorld(true);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	override public function undo():Void {
		this.object.rotation.copy(this.oldRotation);
		this.object.updateMatrixWorld(true);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	override public function update(command:Command):Void {
		var command = cast(command, SetRotationCommand);
		this.newRotation.copy(command.newRotation);
	}

	override public function toJSON():Dynamic {
		var output = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.oldRotation = this.oldRotation.toArray();
		output.newRotation = this.newRotation.toArray();

		return output;
	}

	override public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.object = this.editor.objectByUuid(json.objectUuid);
		this.oldRotation = new Euler().fromArray(json.oldRotation);
		this.newRotation = new Euler().fromArray(json.newRotation);
	}
}