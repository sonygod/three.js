import three.js.editor.js.commands.Command;

class SetMaterialColorCommand extends Command {

	public function new(editor:Editor, object:THREE.Object3D = null, attributeName:String = '', newValue:Int = null, materialSlot:Int = -1) {
		super(editor);

		this.type = 'SetMaterialColorCommand';
		this.name = editor.strings.getKey('command/SetMaterialColor') + ': ' + attributeName;
		this.updatable = true;

		this.object = object;
		this.materialSlot = materialSlot;

		var material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

		this.oldValue = (material != null) ? material[attributeName].getHex() : null;
		this.newValue = newValue;

		this.attributeName = attributeName;
	}

	public function execute() {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
		material[this.attributeName].setHex(this.newValue);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function undo() {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
		material[this.attributeName].setHex(this.oldValue);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function update(cmd:Command) {
		this.newValue = cmd.newValue;
	}

	public function toJSON() {
		var output = super.toJSON(this);
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