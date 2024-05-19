package three.js.editor.commands;

import three.js.editor.Command;

class SetColorCommand extends Command {
    public var object:three.js.THREE.Object3D;
    public var attributeName:String;
    public var oldValue:Int;
    public var newValue:Int;

    public function new(editor:Editor, object:three.js.THREE.Object3D = null, attributeName:String = '', newValue:Int = null) {
        super(editor);

        this.type = 'SetColorCommand';
        this.name = editor.strings.getKey('command/SetColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? object[attributeName].getHex() : null;
        this.newValue = newValue;
    }

    public function execute():Void {
        object[attributeName].setHex(newValue);
        editor.signals.objectChanged.dispatch(object);
    }

    public function undo():Void {
        object[attributeName].setHex(oldValue);
        editor.signals.objectChanged.dispatch(object);
    }

    public function update(cmd:SetColorCommand):Void {
        newValue = cmd.newValue;
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        object = editor.objectByUuid(json.objectUuid);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
    }
}