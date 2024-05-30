import three.js.editor.js.commands.Command;

class SetMaterialRangeCommand extends Command {

	public function new(editor:Editor, object:THREE.Object3D = null, attributeName:String = '', newMinValue:Float = -Infinity, newMaxValue:Float = Infinity, materialSlot:Int = -1) {
		super(editor);

		this.type = 'SetMaterialRangeCommand';
		this.name = editor.strings.getKey('command/SetMaterialRange') + ': ' + attributeName;
		this.updatable = true;

		this.object = object;
		this.materialSlot = materialSlot;

		var material = (object !== null) ? editor.getObjectMaterial(object, materialSlot) : null;

		this.oldRange = (material !== null && material[attributeName] !== undefined) ? [...material[attributeName]] : null;
		this.newRange = [newMinValue, newMaxValue];

		this.attributeName = attributeName;
	}

	public function execute() {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

		material[this.attributeName] = [...this.newRange];
		material.needsUpdate = true;

		this.editor.signals.objectChanged.dispatch(this.object);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function undo() {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

		material[this.attributeName] = [...this.oldRange];
		material.needsUpdate = true;

		this.editor.signals.objectChanged.dispatch(this.object);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function update(cmd:Command) {
		this.newRange = [...cmd.newRange];
	}

	public function toJSON() {
		var output = super.toJSON(this);

		output.objectUuid = this.object.uuid;
		output.attributeName = this.attributeName;
		output.oldRange = [...this.oldRange];
		output.newRange = [...this.newRange];
		output.materialSlot = this.materialSlot;

		return output;
	}

	public function fromJSON(json:Dynamic) {
		super.fromJSON(json);

		this.attributeName = json.attributeName;
		this.oldRange = [...json.oldRange];
		this.newRange = [...json.newRange];
		this.object = this.editor.objectByUuid(json.objectUuid);
		this.materialSlot = json.materialSlot;
	}
}