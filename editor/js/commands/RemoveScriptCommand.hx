package three.js.editor.commands;

import three.js.editor.Command;

class RemoveScriptCommand extends Command {
    public var type:String;
    public var name:String;
    public var object:threed.Object3D;
    public var script:String;
    public var index:Int;

    public function new(editor:Editor, object:threed.Object3D = null, script:String = '') {
        super(editor);
        this.type = 'RemoveScriptCommand';
        this.name = editor.getString('command/RemoveScript');
        this.object = object;
        this.script = script;

        if (object != null && script != '') {
            this.index = editor.scripts.get(object.uuid).indexOf(script);
        }
    }

    public function execute():Void {
        if (editor.scripts.get(object.uuid) == null) return;
        if (index != -1) {
            editor.scripts.get(object.uuid).splice(index, 1);
        }
        editor.signals.scriptRemoved.dispatch(script);
    }

    public function undo():Void {
        if (editor.scripts.get(object.uuid) == null) {
            editor.scripts.set(object.uuid, []);
        }
        editor.scripts.get(object.uuid).splice(index, 0, script);
        editor.signals.scriptAdded.dispatch(script);
    }

    public function toJSON():Dynamic {
        var output:Dynamic = super.toJSON(this);
        output.objectUuid = object.uuid;
        output.script = script;
        output.index = index;
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        script = json.script;
        index = json.index;
        object = editor.objectByUuid(json.objectUuid);
    }
}