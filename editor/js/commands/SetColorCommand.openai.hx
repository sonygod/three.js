package three.js.editor.commands;

import three.js.editor.commands.Command;

class SetColorCommand extends Command {
    public var editor:Editor;
    public var object:Object3D;
    public var attributeName:String;
    public var oldValue:Int;
    public var newValue:Int;

    public function new(editor:Editor, object:Object3D = null, attributeName:String = "", newValue:Int = 0) {
        super(editor);

        this.type = 'SetColorCommand';
        this.name = editor.strings.getKey('command/SetColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? object[attributeName].getHex() : null;
        this.newValue = newValue;
    }

    public function execute() {
        object[attributeName].setHex(newValue);
        editor.signals.objectChanged.dispatch(object);
    }

    public function undo() {
        object[attributeName].setHex(oldValue);
        editor.signals.objectChanged.dispatch(object);
    }

    public function update(cmd:SetColorCommand) {
        newValue = cmd.newValue;
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);
        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        object = editor.objectByUuid(json.objectUuid);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
    }
}