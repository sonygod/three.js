import Command from '../Command';

class SetMaterialRangeCommand extends Command {
	public var type:String;
	public var name:String;
	public var updatable:Bool;
	public var object:Dynamic;
	public var materialSlot:Int;
	public var oldRange:Array<Float>;
	public var newRange:Array<Float>;
	public var attributeName:String;

	public function new(editor:Editor, object:Dynamic = null, attributeName:String = '', newMinValue:Float = -Float.POSITIVE_INFINITY, newMaxValue:Float = Float.POSITIVE_INFINITY, materialSlot:Int = -1) {
		super(editor);

		this.type = 'SetMaterialRangeCommand';
		this.name = editor.strings.getKey('command/SetMaterialRange') + ': ' + attributeName;
		this.updatable = true;
		this.object = object;
		this.materialSlot = materialSlot;

		var material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;
		if (material != null && Reflect.hasField(material, attributeName)) {
			this.oldRange = Array.copy(Reflect.field(material, attributeName));
		} else {
			this.oldRange = null;
		}
		this.newRange = [newMinValue, newMaxValue];
		this.attributeName = attributeName;
	}

	@Override
	public function execute():Void {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
		Reflect.setField(material, this.attributeName, Array.copy(this.newRange));
		material.needsUpdate = true;

		this.editor.signals.objectChanged.dispatch(this.object);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	@Override
	public function undo():Void {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
		Reflect.setField(material, this.attributeName, Array.copy(this.oldRange));
		material.needsUpdate = true;

		this.editor.signals.objectChanged.dispatch(this.object);
		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function update(cmd:SetMaterialRangeCommand):Void {
		this.newRange = Array.copy(cmd.newRange);
	}

	@Override
	public function toJSON():Dynamic {
		var output = super.toJSON();
		output.objectUuid = this.object.uuid;
		output.attributeName = this.attributeName;
		output.oldRange = Array.copy(this.oldRange);
		output.newRange = Array.copy(this.newRange);
		output.materialSlot = this.materialSlot;
		return output;
	}

	@Override
	public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.attributeName = json.attributeName;
		this.oldRange = Array.copy(json.oldRange);
		this.newRange = Array.copy(json.newRange);
		this.object = this.editor.objectByUuid(json.objectUuid);
		this.materialSlot = json.materialSlot;
	}
}