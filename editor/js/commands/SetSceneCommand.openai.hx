package three.js.editor.js.commands;

import three.js.editor.js.Command;
import three.js.editor.js.commands.SetUuidCommand;
import three.js.editor.js.commands.SetValueCommand;
import three.js.editor.js.commands.AddObjectCommand;

class SetSceneCommand extends Command {

    public var cmdArray:Array<Command>;

    public function new(editor:Editor, ?scene:Dynamic) {
        super(editor);
        type = 'SetSceneCommand';
        name = editor.strings.getKey('command/SetScene');

        cmdArray = [];

        if (scene != null) {
            cmdArray.push(new SetUuidCommand(editor, editor.scene, scene.uuid));
            cmdArray.push(new SetValueCommand(editor, editor.scene, 'name', scene.name));
            cmdArray.push(new SetValueCommand(editor, editor.scene, 'userData', Json.parse(Json.stringify(scene.userData))));

            while (scene.children.length > 0) {
                var child = scene.children.pop();
                cmdArray.push(new AddObjectCommand(editor, child));
            }
        }
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

        for (i in cmdArray.length - 1...0) {
            cmdArray[i].undo();
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);

        var cmds:Array<Dynamic> = [];
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
            var cmdType:String = cmds[i].type;
            var cmd:Command = Type.createInstance(Type.resolveClass(cmdType), []);
            cmd.fromJSON(cmds[i]);
            cmdArray.push(cmd);
        }
    }
}