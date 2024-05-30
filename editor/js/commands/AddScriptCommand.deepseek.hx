import three.js.editor.js.commands.Command;

class AddScriptCommand extends Command {

	public function new(editor:Editor, ?object:THREE.Object3D, script:Dynamic) {
		super(editor);

		this.type = 'AddScriptCommand';
		this.name = editor.strings.getKey('command/AddScript');

		this.object = object;
		this.script = script;
	}

	public function execute():Void {
		if (this.editor.scripts[this.object.uuid] == null) {
			this.editor.scripts[this.object.uuid] = [];
		}

		this.editor.scripts[this.object.uuid].push(this.script);
		this.editor.signals.scriptAdded.dispatch(this.script);
	}

	public function undo():Void {
		if (this.editor.scripts[this.object.uuid] == null) return;

		var index = this.editor.scripts[this.object.uuid].indexOf(this.script);

		if (index != -1) {
			this.editor.scripts[this.object.uuid].splice(index, 1);
		}

		this.editor.signals.scriptRemoved.dispatch(this.script);
	}

	public function toJSON():Dynamic {
		var output = super.toJSON(this);

		output.objectUuid = this.object.uuid;
		output.script = this.script;

		return output;
	}

	public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.script = json.script;
		this.object = this.editor.objectByUuid(json.objectUuid);
	}
}