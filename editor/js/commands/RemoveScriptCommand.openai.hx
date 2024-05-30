package three.js.editor.commands;

import three.js.editor.commands.Command;

class RemoveScriptCommand extends Command {
    public var object:THREE.Object3D;
    public var script:Dynamic;
    public var index:Int;

    public function new(editor:Editor, object:THREE.Object3D = null, script:Dynamic = '') {
        super(editor);

        this.type = 'RemoveScriptCommand';
        this.name = editor.strings.getKey('command/RemoveScript');

        this.object = object;
        this.script = script;

        if (this.object != null && this.script != '') {
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

        Reflect.setField(output, 'objectUuid', object.uuid);
        Reflect.setField(output, 'script', script);
        Reflect.setField(output, 'index', index);

        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        script = Reflect.field(json, 'script');
        index = Reflect.field(json, 'index');
        object = editor.objectByUuid(Reflect.field(json, 'objectUuid'));
    }
}