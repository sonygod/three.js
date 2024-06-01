import js.Lib;

class SetSceneCommand extends Command {

	public function new(editor : Editor, scene : Scene = null) {
		super(editor);

		this.type = 'SetSceneCommand';
		this.name = editor.strings.getKey('command/SetScene');

		this.cmdArray = [];

		if (scene != null) {
			this.cmdArray.push(new SetUuidCommand(this.editor, this.editor.scene, scene.uuid));
			this.cmdArray.push(new SetValueCommand(this.editor, this.editor.scene, 'name', scene.name));
			this.cmdArray.push(new SetValueCommand(this.editor, this.editor.scene, 'userData', Lib.parseString(Lib.stringify(scene.userData))));

			while (scene.children.length > 0) {
				var child = scene.children.pop();
				this.cmdArray.push(new AddObjectCommand(this.editor, child));
			}
		}
	}

	override public function execute() : Void {
		this.editor.signals.sceneGraphChanged.active = false;

		for (i in 0...this.cmdArray.length) {
			this.cmdArray[i].execute();
		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.sceneGraphChanged.dispatch();
	}

	override public function undo() : Void {
		this.editor.signals.sceneGraphChanged.active = false;

		for (i in this.cmdArray.length - 1...0) {
			this.cmdArray[i].undo();
		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.sceneGraphChanged.dispatch();
	}

	override public function toJSON() : Dynamic {
		var output = super.toJSON();

		var cmds = [];
		for (i in 0...this.cmdArray.length) {
			cmds.push(this.cmdArray[i].toJSON());
		}

		output.cmds = cmds;

		return output;
	}

	override public function fromJSON(json : Dynamic) : Void {
		super.fromJSON(json);

		var cmds : Array<Dynamic> = json.cmds;
		for (i in 0...cmds.length) {
			var cmd : Command = Type.createInstance(Type.resolveClass(cmds[i].type), []); // creates a new object of type "json.type"
			cmd.fromJSON(cmds[i]);
			this.cmdArray.push(cmd);
		}
	}
}