Here is the converted Haxe code:
```
package three.js.editor.js.commands;

import three.js.editor.js.Command;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param script javascript object
 * @constructor
 */
class AddScriptCommand extends Command {

    public var object : Dynamic;
    public var script : String;

    public function new(editor : Editor, object : Dynamic = null, script : String = '') {
        super(editor);

        this.type = 'AddScriptCommand';
        this.name = editor.strings.getKey('command/AddScript');

        this.object = object;
        this.script = script;
    }

    public override function execute() : Void {
        if (!editor.scripts.exists(this.object.uuid)) {
            editor.scripts.set(this.object.uuid, []);
        }

        editor.scripts.get(this.object.uuid).push(this.script);

        editor.signals.scriptAdded.dispatch(this.script);
    }

    public override function undo() : Void {
        if (!editor.scripts.exists(this.object.uuid)) return;

        var index = Lambda.indexOf(editor.scripts.get(this.object.uuid), this.script);

        if (index != -1) {
            editor.scripts.get(this.object.uuid).splice(index, 1);
        }

        editor.signals.scriptRemoved.dispatch(this.script);
    }

    public override function toJSON() : Dynamic {
        var output = super.toJSON(this);

        Reflect.setField(output, 'objectUuid', this.object.uuid);
        Reflect.setField(output, 'script', this.script);

        return output;
    }

    public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);

        this.script = json.script;
        this.object = editor.objectByUuid(json.objectUuid);
    }
}
```
Note that I've used the `Dynamic` type for the `object` field, as it's not clear what type it should be. You may need to adjust this depending on your specific use case. Additionally, I've used the `Lambda` class to implement the `indexOf` function, as Haxe doesn't have a built-in equivalent.