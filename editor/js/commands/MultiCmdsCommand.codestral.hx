import Command;

class MultiCmdsCommand extends Command {
    public var type:String = 'MultiCmdsCommand';
    public var name:String;
    public var cmdArray:Array<Command> = [];

    public function new(editor:Editor, cmdArray:Array<Command> = []) {
        super(editor);
        this.name = editor.strings.getKey('command/MultiCmds');
        this.cmdArray = cmdArray;
    }

    public function execute():Void {
        editor.signals.sceneGraphChanged.active = false;

        for (i in 0...this.cmdArray.length) {
            this.cmdArray[i].execute();
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo():Void {
        editor.signals.sceneGraphChanged.active = false;

        for (i in (this.cmdArray.length - 1)...-1) {
            this.cmdArray[i].undo();
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        var cmds = [];

        for (i in 0...this.cmdArray.length) {
            cmds.push(this.cmdArray[i].toJSON());
        }

        output.cmds = cmds;
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        var cmds = json.cmds;
        for (i in 0...cmds.length) {
            var cmdClass = Type.resolveClass(cmds[i].type);
            var cmd = Type.createInstance(cmdClass, []);
            cmd.fromJSON(cmds[i]);
            this.cmdArray.push(cmd);
        }
    }
}