import three.js.editor.js.commands.Command;

class SetMaterialVectorCommand extends Command {

	public function new(editor:Dynamic, object:Dynamic = null, attributeName:String = '', newValue:Dynamic = null, materialSlot:Int = -1) {
		super(editor);

		this.type = 'SetMaterialVectorCommand';
		this.name = editor.strings.getKey('command/SetMaterialVector') + ': ' + attributeName;
		this.updatable = true;

		this.object = object;
		this.materialSlot = materialSlot;

		var material = (object !== null) ? editor.getObjectMaterial(object, materialSlot) : null;

		this.oldValue = (material !== null) ? material[attributeName].toArray() : null;
		this.newValue = newValue;

		this.attributeName = attributeName;
	}

	public function execute() {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
		material[this.attributeName].fromArray(this.newValue);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function undo() {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
		material[this.attributeName].fromArray(this.oldValue);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function update(cmd:Dynamic) {
		this.newValue = cmd.newValue;
	}

	public function toJSON() {
		var output = super.toJSON();
		output.objectUuid = this.object.uuid;
		output.attributeName = this.attributeName;
		output.oldValue = this.oldValue;
		output.newValue = this.newValue;
		output.materialSlot = this.materialSlot;
		return output;
	}

	public function fromJSON(json:Dynamic) {
		super.fromJSON(json);
		this.object = this.editor.objectByUuid(json.objectUuid);
		this.attributeName = json.attributeName;
		this.oldValue = json.oldValue;
		this.newValue = json.newValue;
		this.materialSlot = json.materialSlot;
	}
}