package three.js.editor.js.commands;

import three.js.editor.js.commands.Command;
import three.js.editor.js.commands.SetUuidCommand;
import three.js.editor.js.commands.SetValueCommand;
import three.js.editor.js.commands.AddObjectCommand;

class SetSceneCommand extends Command {
    public var cmdArray:Array<Command>;

    public function new(editor:Editor, scene:Scene = null) {
        super(editor);

        this.type = 'SetSceneCommand';
        this.name = editor.strings.getKey('command/SetScene');

        this.cmdArray = [];

        if (scene != null) {
            this.cmdArray.push(new SetUuidCommand(editor, editor.scene, scene.uuid));
            this.cmdArray.push(new SetValueCommand(editor, editor.scene, 'name', scene.name));
            this.cmdArray.push(new SetValueCommand(editor, editor.scene, 'userData', Json.parse(Json.stringify(scene.userData))));

            while (scene.children.length > 0) {
                var child = scene.children.pop();
                this.cmdArray.push(new AddObjectCommand(editor, child));
            }
        }
    }

    public override function execute():Void {
        editor.signals.sceneGraphChanged.active = false;

        for (i in 0...cmdArray.length) {
            cmdArray[i].execute();
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public override function undo():Void {
        editor.signals.sceneGraphChanged.active = false;

        for (i in cmdArray.length - 1...-1) {
            cmdArray[i].undo();
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public override function toJSON():Dynamic {
        var output = super.toJSON(this);

        var cmds:Array<Dynamic> = [];
        for (i in 0...cmdArray.length) {
            cmds.push(cmdArray[i].toJSON());
        }

        output.cmds = cmds;

        return output;
    }

    public override function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        var cmds:Array<Dynamic> = json.cmds;
        for (i in 0...cmds.length) {
            var cmd:Command = Type.createInstance(Type.resolveClass(cmds[i].type), []);
            cmd.fromJSON(cmds[i]);
            this.cmdArray.push(cmd);
        }
    }
}