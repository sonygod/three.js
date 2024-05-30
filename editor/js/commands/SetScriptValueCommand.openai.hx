package three.editor.js.commands;

import js.lib.Object;
import three.editor.js.commands.Command;

class SetScriptValueCommand extends Command {
    public var object : three.Object3D;
    public var script : Dynamic;
    public var attributeName : String;
    public var oldValue : Dynamic;
    public var newValue : Dynamic;

    public function new(editor : Editor, object : three.Object3D = null, script : Dynamic = '', attributeName : String = '', newValue : Dynamic = null) {
        super(editor);

        this.type = 'SetScriptValueCommand';
        this.name = editor.strings.getKey('command/SetScriptValue') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.script = script;

        this.attributeName = attributeName;
        this.oldValue = (script != '') ? script[attributeName] : null;
        this.newValue = newValue;
    }

    public function execute() {
        script[attributeName] = newValue;

        editor.signals.scriptChanged.dispatch();
    }

    public function undo() {
        script[attributeName] = oldValue;

        editor.signals.scriptChanged.dispatch();
    }

    public function update(cmd : SetScriptValueCommand) {
        newValue = cmd.newValue;
    }

    public function toJSON() : Dynamic {
        var output : Dynamic = super.toJSON();

        output.objectUuid = object.uuid;
        output.index = editor.scripts[object.uuid].indexOf(script);
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;

        return output;
    }

    public function fromJSON(json : Dynamic) {
        super.fromJSON(json);

        oldValue = json.oldValue;
        newValue = json.newValue;
        attributeName = json.attributeName;
        object = editor.objectByUuid(json.objectUuid);
        script = editor.scripts[json.objectUuid][json.index];
    }
}