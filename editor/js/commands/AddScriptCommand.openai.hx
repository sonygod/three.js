package three.js.editor.commands;

import three.js.editor.Command;

class AddScriptCommand extends Command {
    
    public var object:three.js.THREE.Object3D;
    public var script:String;

    public function new(editor:Editor, ?object:three.js.THREE.Object3D, ?script:String = '') {
        super(editor);
        this.type = 'AddScriptCommand';
        this.name = editor.getString('command/AddScript');

        this.object = object;
        this.script = script;
    }

    override public function execute():Void {
        if (!editor.scripts.exists(object.uuid)) {
            editor.scripts[object.uuid] = [];
        }
        editor.scripts[object.uuid].push(script);
        editor.signals.scriptAdded.dispatch(script);
    }

    override public function undo():Void {
        if (!editor.scripts.exists(object.uuid)) return;
        var index = editor.scripts[object.uuid].indexOf(script);
        if (index != -1) {
            editor.scripts[object.uuid].splice(index, 1);
        }
        editor.signals.scriptRemoved.dispatch(script);
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.script = script;
        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        script = json.script;
        object = editor.getObjectByUuid(json.objectUuid);
    }
}