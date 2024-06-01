import haxe.Json;

class MultiCmdsCommand extends Command {

	public var cmdArray:Array<Command>;

	public function new(editor:Editor, cmdArray:Array<Command> = null) {

		super(editor);

		this.type = 'MultiCmdsCommand';
		this.name = editor.strings.getKey('command/MultiCmds');

		if (cmdArray == null) {
			cmdArray = [];
		}
		this.cmdArray = cmdArray;

	}

	override public function execute():Void {

		this.editor.signals.sceneGraphChanged.active = false;

		for (i in 0...this.cmdArray.length) {

			this.cmdArray[i].execute();

		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.sceneGraphChanged.dispatch();

	}

	override public function undo():Void {

		this.editor.signals.sceneGraphChanged.active = false;

		for (i in this.cmdArray.length - 1...0) {

			this.cmdArray[i].undo();

		}

		this.editor.signals.sceneGraphChanged.active = true;
		this.editor.signals.sceneGraphChanged.dispatch();

	}

	override public function toJSON():Dynamic {

		var output = super.toJSON();

		var cmds = [];
		for (i in 0...this.cmdArray.length) {

			cmds.push(this.cmdArray[i].toJSON());

		}

		Reflect.setField(output, "cmds", cmds);

		return output;

	}

	override public function fromJSON(json:Dynamic):Void {

		super.fromJSON(json);

		var cmds:Array<Dynamic> = Reflect.field(json, "cmds");
		for (i in 0...cmds.length) {

			var cmd:Command = Type.createInstance(Type.resolveClass(Reflect.field(cmds[i], "type")), []); // creates a new object of type "json.type"
			cmd.fromJSON(cmds[i]);
			this.cmdArray.push(cmd);

		}

	}

}