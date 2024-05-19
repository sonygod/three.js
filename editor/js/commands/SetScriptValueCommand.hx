package three.js.editor.commands;

import three.js.editor.Command;

class SetScriptValueCommand extends Command {
    public var type:String;
    public var name:String;
    public var updatable:Bool;
    public var object:Dynamic;
    public var script:Dynamic;
    public var attributeName:String;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;

    public function new(editor:Dynamic, object:Dynamic = null, script:Dynamic = '', attributeName:String = '', newValue:Dynamic = null) {
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

    public function execute():Void {
        script[attributeName] = newValue;

        editor.signals.scriptChanged.dispatch();
    }

    public function undo():Void {
        script[attributeName] = oldValue;

        editor.signals.scriptChanged.dispatch();
    }

    public function update(cmd:SetScriptValueCommand):Void {
        this.newValue = cmd.newValue;
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);

        output.objectUuid = object.uuid;
        output.index = editor.scripts[object.uuid].indexOf(script);
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;

        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
        this.attributeName = json.attributeName;
        this.object = editor.objectByUuid(json.objectUuid);
        this.script = editor.scripts[json.objectUuid][json.index];
    }
}