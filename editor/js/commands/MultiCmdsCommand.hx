package three.js.editor.commands;

import three.js.editor.Command;

class MultiCmdsCommand extends Command {
    public var cmdArray:Array<Command>;

    public function new(editor:Editor, ?cmdArray:Array<Command>) {
        super(editor);
        this.type = 'MultiCmdsCommand';
        this.name = editor.strings.getKey('command/MultiCmds');
        this.cmdArray = cmdArray != null ? cmdArray : new Array<Command>();
    }

    public function execute():Void {
        editor.signals.sceneGraphChanged.active = false;
        for (i in 0...cmdArray.length) {
            cmdArray[i].execute();
        }
        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo():Void {
        editor.signals.sceneGraphChanged.active = false;
        for (i in cmdArray.length - 1...-1) {
            cmdArray[i].undo();
        }
        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Dynamic {
        var output:Dynamic = super.toJSON(this);
        var cmds:Array<Dynamic> = new Array<Dynamic>();
        for (i in 0...cmdArray.length) {
            cmds.push(cmdArray[i].toJSON());
        }
        output.cmds = cmds;
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        var cmds:Array<Dynamic> = json.cmds;
        for (i in 0...cmds.length) {
            var cmd:Command = Type.createInstance(Type.resolveClass(cmds[i].type), []);
            cmd.fromJSON(cmds[i]);
            cmdArray.push(cmd);
        }
    }
}