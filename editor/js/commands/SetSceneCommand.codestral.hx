import Command;
import SetUuidCommand;
import SetValueCommand;
import AddObjectCommand;
import haxe.Json;

class SetSceneCommand extends Command {
    public var type:String;
    public var name:String;
    public var cmdArray:Array<Command>;

    public function new(editor:Editor, scene:Scene? = null) {
        super(editor);

        this.type = "SetSceneCommand";
        this.name = editor.strings.getKey("command/SetScene");

        this.cmdArray = [];

        if (scene != null) {
            this.cmdArray.push(new SetUuidCommand(editor, editor.scene, scene.uuid));
            this.cmdArray.push(new SetValueCommand(editor, editor.scene, "name", scene.name));
            this.cmdArray.push(new SetValueCommand(editor, editor.scene, "userData", Json.parse(Json.stringify(scene.userData))));

            while (scene.children.length > 0) {
                var child = scene.children.pop();
                this.cmdArray.push(new AddObjectCommand(editor, child));
            }
        }
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

        for (i in this.cmdArray.length - 1...-1) {
            this.cmdArray[i].undo();
        }

        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);

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
            var cmd = Type.createInstance(Type.resolveClass(cmds[i].type), []);
            cmd.fromJSON(cmds[i]);
            this.cmdArray.push(cmd);
        }
    }
}