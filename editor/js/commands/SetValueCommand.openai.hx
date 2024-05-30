package three.js.editor.commands;

import three.js.editor.Command;

class SetValueCommand extends Command {
	public var objectType: three.js.Object3D;
	public var attributeName: String;
	public var oldValue: Dynamic;
	public var newValue: Dynamic;

	public function new(editor: Editor, object: three.js.Object3D = null, attributeName: String = '', newValue: Dynamic = null) {
		super(editor);

		this.type = 'SetValueCommand';
		this.name = editor.strings.getKey('command/SetValue') + ': ' + attributeName;
		this.updatable = true;

		this.objectType = object;
		this.attributeName = attributeName;
		this.oldValue = (object != null) ? Reflect.field(object, attributeName) : null;
		this.newValue = newValue;
	}

	override public function execute(): Void {
		Reflect.setField(objectType, attributeName, newValue);
		editor.signals.objectChanged.dispatch(objectType);
		// editor.signals.sceneGraphChanged.dispatch();
	}

	override public function undo(): Void {
		Reflect.setField(objectType, attributeName, oldValue);
		editor.signals.objectChanged.dispatch(objectType);
		// editor.signals.sceneGraphChanged.dispatch();
	}

	override public function update(cmd: SetValueCommand): Void {
		newValue = cmd.newValue;
	}

	override public function toJSON(): Dynamic {
		var output = super.toJSON();
		output.objectUuid = objectType.uuid;
		output.attributeName = attributeName;
		output.oldValue = oldValue;
		output.newValue = newValue;
		return output;
	}

	override public function fromJSON(json: Dynamic): Void {
		super.fromJSON(json);
		attributeName = json.attributeName;
		oldValue = json.oldValue;
		newValue = json.newValue;
		objectType = editor.objectByUuid(json.objectUuid);
	}
}