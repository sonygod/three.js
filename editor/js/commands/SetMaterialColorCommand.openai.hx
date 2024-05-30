package three.js.editor.js.commands;

import commands.Command;

class SetMaterialColorCommand extends Command {
    public var object:three.js.Object3D;
    public var attributeName:String;
    public var materialSlot:Int;
    public var oldValue:Null<Int>;
    public var newValue:Int;

    public function new(editor:Editor, object:three.js.Object3D = null, attributeName:String = '', newValue:Int = 0, materialSlot:Int = -1) {
        super(editor);
        this.type = 'SetMaterialColorCommand';
        this.name = editor.getString('command/SetMaterialColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material:three.js.Material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldValue = (material != null) ? material[attributeName].getHex() : null;
        this.newValue = newValue;

        this.attributeName = attributeName;
    }

    public function execute():Void {
        var material:three.js.Material = editor.getObjectMaterial(object, materialSlot);
        material[attributeName].setHex(newValue);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo():Void {
        var material:three.js.Material = editor.getObjectMaterial(object, materialSlot);
        material[attributeName].setHex(oldValue);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function update(cmd:SetMaterialColorCommand):Void {
        newValue = cmd.newValue;
    }

    public function toJSON():Dynamic {
        var output:Dynamic = super.toJSON();
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