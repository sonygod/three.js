import three.core.Object3D;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param script Dynamic
 * @constructor
 */
class AddScriptCommand extends Command {

	public var object:Object3D;
	public var script:Dynamic;

	public function new(editor:Editor, object:Object3D = null, script:Dynamic = "") {

		super(editor);

		this.type = 'AddScriptCommand';
		this.name = editor.strings.getKey('command/AddScript');

		this.object = object;
		this.script = script;

	}

	override public function execute():Void {

		if (this.editor.scripts[this.object.uuid] == null) {

			this.editor.scripts[this.object.uuid] = [];

		}

		this.editor.scripts[this.object.uuid].push(this.script);

		this.editor.signals.scriptAdded.dispatch(this.script);

	}

	override public function undo():Void {

		if (this.editor.scripts[this.object.uuid] == null) return;

		var index:Int = this.editor.scripts[this.object.uuid].indexOf(this.script);

		if (index != -1) {

			this.editor.scripts[this.object.uuid].splice(index, 1);

		}

		this.editor.signals.scriptRemoved.dispatch(this.script);

	}

	override public function toJSON():Dynamic {

		var output:Dynamic = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.script = this.script;

		return output;

	}

	override public function fromJSON(json:Dynamic):Void {

		super.fromJSON(json);

		this.script = json.script;
		this.object = this.editor.objectByUuid(json.objectUuid);

	}

}