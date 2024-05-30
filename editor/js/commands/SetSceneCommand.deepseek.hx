import three.js.editor.js.commands.Command;
import three.js.editor.js.commands.SetUuidCommand;
import three.js.editor.js.commands.SetValueCommand;
import three.js.editor.js.commands.AddObjectCommand;

class SetSceneCommand extends Command {

	public function new(editor:Editor, scene:Scene = null) {
		super(editor);
		this.type = 'SetSceneCommand';
		this.name = editor.strings.getKey('command/SetScene');
		this.cmdArray = [];

		if (scene !== null) {
			this.cmdArray.push(new SetUuidCommand(this.editor, this.editor.scene, scene.uuid));
			this.cmdArray.push(new SetValueCommand(this.editor, this.editor.scene, 'name', scene.name));
			this.cmdArray.push(new SetValueCommand(this.editor, this.editor.scene, 'userData', Std.parseJson(Std.stringify(scene.userData))));

			while (scene.children.length > 0) {
				var child = scene.children.pop();
				this.cmdArray.push(new AddObjectCommand(this.editor, child));
			}
		}
	}

	public function execute():Void {
		this.editor.signals.sceneGraphChanged.active = false;
		for (i in this.cmdArray) {
			this.cmdArray[i].execute();
		}
		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.sceneGraphChanged.dispatch();
	}

	public function undo():Void {
		this.editor.signals.sceneGraphChanged.active = false;
		for (i in this.cmdArray.reverse()) {
			this.cmdArray[i].undo();
		}
		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.sceneGraphChanged.dispatch();
	}

	public function toJSON():Dynamic {
		var output = super.toJSON(this);
		var cmds = [];
		for (i in this.cmdArray) {
			cmds.push(this.cmdArray[i].toJSON());
		}
		output.cmds = cmds;
		return output;
	}

	public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);
		var cmds = json.cmds;
		for (i in cmds) {
			var cmd = Type.createInstance(Type.resolveClass(cmds[i].type), []);
			cmd.fromJSON(cmds[i]);
			this.cmdArray.push(cmd);
		}
	}
}