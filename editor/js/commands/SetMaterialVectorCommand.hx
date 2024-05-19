package three.js.editor.js.commands;

import three.js.editor.commands.Command;

class SetMaterialVectorCommand extends Command {
    public var object:Dynamic;
    public var materialSlot:Int;
    public var attributeName:String;
    public var oldValue:Array<Float>;
    public var newValue:Array<Float>;

    public function new(editor:Dynamic, object:Dynamic = null, attributeName:String = '', newValue:Array<Float> = null, materialSlot:Int = -1) {
        super(editor);

        this.type = 'SetMaterialVectorCommand';
        this.name = editor.strings.getKey('command/SetMaterialVector') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material:Dynamic = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldValue = (material != null) ? material[attributeName].toArray() : null;
        this.newValue = newValue;

        this.attributeName = attributeName;
    }

    public function execute():Void {
        var material:Dynamic = editor.getObjectMaterial(object, materialSlot);

        material[attributeName].fromArray(newValue);

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo():Void {
        var material:Dynamic = editor.getObjectMaterial(object, materialSlot);

        material[attributeName].fromArray(oldValue);

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function update(cmd:SetMaterialVectorCommand):Void {
        newValue = cmd.newValue;
    }

    public function toJSON():Dynamic {
        var output:Dynamic = super.toJSON(this);

        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;
        output.materialSlot = materialSlot;

        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        object = editor.objectByUuid(json.objectUuid);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
        materialSlot = json.materialSlot;
    }
}