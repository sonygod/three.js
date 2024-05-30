import Command from '../Command.hx';
import SetUuidCommand from './SetUuidCommand.hx';
import SetValueCommand from './SetValueCommand.hx';
import AddObjectCommand from './AddObjectCommand.hx';

class SetSceneCommand extends Command {
    public cmdArray:Array<Command>;
    public constructor(editor:Editor, scene:Scene = null) {
        super(editor);
        this.type = 'SetSceneCommand';
        this.name = editor.strings.getKey('command/SetScene');
        this.cmdArray = [];
        if (scene != null) {
            this.cmdArray.push(new SetUuidCommand(editor, editor.scene, scene.uuid));
            this.cmdArray.push(new SetValueCommand(editor, editor.scene, 'name', scene.name));
            this.cmdArray.push(new SetValueCommand(editor, editor.scene, 'userData', Std.string(Json.stringify(scene.userData))));
            while (scene.children.length > 0) {
                let child = scene.children.pop();
                this.cmdArray.push(new AddObjectCommand(editor, child));
            }
        }
    }
    public function execute():Void {
        editor.signals.sceneGraphChanged.active = false;
        for (let i = 0; i < this.cmdArray.length; i++) {
            this.cmdArray[i].execute();
        }
        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }
    public function undo():Void {
        editor.signals.sceneGraphChanged.active = false;
        for (let i = this.cmdArray.length - 1; i >= 0; i--) {
            this.cmdArray[i].undo();
        }
        editor.signals.sceneGraphChanged.active = true;
        editor.signals.sceneGraphChanged.dispatch();
    }
    public function toJSON():Json {
        let output = super.toJSON();
        let cmds = [];
        for (let i = 0; i < this.cmdArray.length; i++) {
            cmds.push(this.cmdArray[i].toJSON());
        }
        output.cmds = cmds;
        return output;
    }
    public function fromJSON(json:Json):Void {
        super.fromJSON(json);
        let cmds = json.cmds;
        for (let i = 0; i < cmds.length; i++) {
            let cmd = Type.createInstance(Type.resolveClass(cmds[i].type), []);
            cmd.fromJSON(cmds[i]);
            this.cmdArray.push(cmd);
        }
    }
}

class SetSceneCommandModule {
    public static function __init__() {
        // Export the class for UMD/CJS
        #if js
            if (typeof exports != "undefined") exports.default = SetSceneCommand;
        #end
    }
}