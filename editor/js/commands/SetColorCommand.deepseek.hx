import three.js.editor.js.commands.Command;

class SetColorCommand extends Command {

	public function new(editor:Editor, object:THREE.Object3D = null, attributeName:String = '', newValue:Int = null) {
		super(editor);

		this.type = 'SetColorCommand';
		this.name = editor.strings.getKey('command/SetColor') + ': ' + attributeName;
		this.updatable = true;

		this.object = object;
		this.attributeName = attributeName;
		this.oldValue = (object != null) ? this.object[this.attributeName].getHex() : null;
		this.newValue = newValue;
	}

	public function execute():Void {
		this.object[this.attributeName].setHex(this.newValue);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	public function undo():Void {
		this.object[this.attributeName].setHex(this.oldValue);
		this.editor.signals.objectChanged.dispatch(this.object);
	}

	public function update(cmd:Dynamic):Void {
		this.newValue = cmd.newValue;
	}

	public function toJSON():Dynamic {
		var output = super.toJSON(this);

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