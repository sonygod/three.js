import three.js.editor.js.commands.Command;

class RemoveScriptCommand extends Command {

	public function new(editor:Editor, object:THREE.Object3D = null, script:Dynamic = '') {
		super(editor);

		this.type = 'RemoveScriptCommand';
		this.name = editor.strings.getKey('command/RemoveScript');

		this.object = object;
		this.script = script;

		if (this.object !== null && this.script !== '') {
			this.index = this.editor.scripts[this.object.uuid].indexOf(this.script);
		}
	}

	public function execute():Void {
		if (this.editor.scripts[this.object.uuid] === undefined) return;

		if (this.index !== -1) {
			this.editor.scripts[this.object.uuid].splice(this.index, 1);
		}

		this.editor.signals.scriptRemoved.dispatch(this.script);
	}

	public function undo():Void {
		if (this.editor.scripts[this.object.uuid] === undefined) {
			this.editor.scripts[this.object.uuid] = [];
		}

		this.editor.scripts[this.object.uuid].splice(this.index, 0, this.script);
		this.editor.signals.scriptAdded.dispatch(this.script);
	}

	public function toJSON():Dynamic {
		var output = super.toJSON(this);

		output.objectUuid = this.object.uuid;
		output.script = this.script;
		output.index = this.index;

		return output;
	}

	public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.script = json.script;
		this.index = json.index;
		this.object = this.editor.objectByUuid(json.objectUuid);
	}
}