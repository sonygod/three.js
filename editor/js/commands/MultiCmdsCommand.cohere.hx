import Command from '../Command.hx';

class MultiCmdsCommand extends Command {
    public var cmdArray:Array<Command>;

    public function new(editor:Editor, cmdArray:Array<Command> = []) {
        super(editor);
        this.type = 'MultiCmdsCommand';
        this.name = editor.strings.getKey('command/MultiCmds');
        this.cmdArray = cmdArray;
    }

    override function execute() {
        editor.signals.sceneGraphChanged.active = false;
        for (cmd in cmdArray) {
            cmd.execute();
        }
        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    override function undo() {
        editor.signals.sceneGraphChanged.active = false;
        for (i in cmdArray.length...0) {
            cmdArray[i].undo();
        }
        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    override function toJSON() {
        var output = super.toJSON();
        output.cmds = cmdArray.map(cmd -> cmd.toJSON());
        return output;
    }

    override function fromJSON(json) {
        super.fromJSON(json);
        for (cmd in json.cmds) {
            var cmdObj = Type.resolveClass(cmd.type);
            var cmdInstance = Reflect.newInstance(cmdObj, []);
            cmdInstance.fromJSON(cmd);
            cmdArray.push(cmdInstance);
        }
    }
}

class export {
    static function __init__() {
        Command.register('MultiCmdsCommand', MultiCmdsCommand);
    }
}