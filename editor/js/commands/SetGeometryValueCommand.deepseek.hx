import three.js.editor.js.commands.Command;

class SetGeometryValueCommand extends Command {

	public function new(editor:Editor, object:THREE.Object3D = null, attributeName:String = '', newValue:Dynamic = null) {
		super(editor);

		this.type = 'SetGeometryValueCommand';
		this.name = editor.strings.getKey('command/SetGeometryValue') + ': ' + attributeName;

		this.object = object;
		this.attributeName = attributeName;
		this.oldValue = (object != null) ? object.geometry[attributeName] : null;
		this.newValue = newValue;
	}

	public function execute():Void {
		this.object.geometry[this.attributeName] = this.newValue;
		this.editor.signals.objectChanged.dispatch(this.object);
		this.editor.signals.geometryChanged.dispatch();
		this.editor.signals.sceneGraphChanged.dispatch();
	}

	public function undo():Void {
		this.object.geometry[this.attributeName] = this.oldValue;
		this.editor.signals.objectChanged.dispatch(this.object);
		this.editor.signals.geometryChanged.dispatch();
		this.editor.signals.sceneGraphChanged.dispatch();
	}

	public function toJSON():Dynamic {
		var output = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.attributeName = this.attributeName;
		output.oldValue = this.oldValue;
		output.newValue = this.newValue;

		return output;
	}

	public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.object = this.editor.objectByUuid(json.objectUuid);
		this.attributeName = json.attributeName;
		this.oldValue = json.oldValue;
		this.newValue = json.newValue;
	}
}