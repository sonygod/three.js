package three.js.editor.commands;

import three.js.editor.commands	Command;

/**
 * @param editor Editor
 * @param cmdArray array containing command objects
 * @constructor
 */
class MultiCmdsCommand extends Command {

	public var cmdArray : Array<Command>;

	public function new( editor : Editor, ?cmdArray : Array<Command> = []) {
		super(editor);
		this.type = 'MultiCmdsCommand';
		this.name = editor.strings.getKey('command/MultiCmds');
		this.cmdArray = cmdArray;
	}

	override public function execute() {
		editor.signals.sceneGraphChanged.active = false;
		for (cmd in cmdArray) {
			cmd.execute();
		}
		editor.signals.sceneGraphChanged.active = true;
		editor.signals.sceneGraphChanged.dispatch();
	}

	override public function undo() {
		editor.signals.sceneGraphChanged.active = false;
		for (cmd in cmdArray.reverse()) {
			cmd.undo();
		}
		editor.signals.sceneGraphChanged.active = true;
		editor.signals.sceneGraphChanged.dispatch();
	}

	override public function toJSON() {
		var output = super.toJSON(this);
		var cmds = [];
		for (cmd in cmdArray) {
			cmds.push(cmd.toJSON());
		}
		output.cmds = cmds;
		return output;
	}

	override public function fromJSON(json) {
		super.fromJSON(json);
		var cmds = json.cmds;
		for (cmd in cmds) {
			var cmdClass : Class<Command> = Type.resolveClass(cmd.type);
			var cmdInstance : Command = Type.createInstance(cmdClass, []);
			cmdInstance.fromJSON(cmd);
			cmdArray.push(cmdInstance);
		}
	}
}