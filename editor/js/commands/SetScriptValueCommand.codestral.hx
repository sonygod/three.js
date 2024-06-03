import Command;
import Editor;
import THREE.Object3D;

class SetScriptValueCommand extends Command {
	public var type:String;
	public var name:String;
	public var updatable:Bool;
	public var object:THREE.Object3D;
	public var script:Dynamic;
	public var attributeName:String;
	public var oldValue:Dynamic;
	public var newValue:Dynamic;

	public function new(editor:Editor, object:THREE.Object3D = null, script:Dynamic = '', attributeName:String = '', newValue:Dynamic = null) {
		super(editor);

		this.type = 'SetScriptValueCommand';
		this.name = editor.strings.getKey('command/SetScriptValue') + ': ' + attributeName;
		this.updatable = true;

		this.object = object;
		this.script = script;

		this.attributeName = attributeName;
		this.oldValue = (script != '') ? Reflect.field(script, this.attributeName) : null;
		this.newValue = newValue;
	}

	public function execute():Void {
		Reflect.setField(this.script, this.attributeName, this.newValue);

		this.editor.signals.scriptChanged.dispatch();
	}

	public function undo():Void {
		Reflect.setField(this.script, this.attributeName, this.oldValue);

		this.editor.signals.scriptChanged.dispatch();
	}

	public function update(cmd:SetScriptValueCommand):Void {
		this.newValue = cmd.newValue;
	}

	override public function toJSON():Dynamic {
		var output = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.index = this.editor.scripts[this.object.uuid].indexOf(this.script);
		output.attributeName = this.attributeName;
		output.oldValue = this.oldValue;
		output.newValue = this.newValue;

		return output;
	}

	override public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.oldValue = json.oldValue;
		this.newValue = json.newValue;
		this.attributeName = json.attributeName;
		this.object = this.editor.objectByUuid(json.objectUuid);
		this.script = this.editor.scripts[json.objectUuid][json.index];
	}
}