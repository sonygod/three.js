import three.js.editor.js.commands.Command;

class MultiCmdsCommand extends Command {

	public function new(editor:Dynamic, cmdArray:Array<Dynamic> = []) {
		super(editor);
		this.type = 'MultiCmdsCommand';
		this.name = editor.strings.getKey('command/MultiCmds');
		this.cmdArray = cmdArray;
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