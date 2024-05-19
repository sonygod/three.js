package three.js.editor.commands;

import three.js.editor.commands.Command;

class SetMaterialColorCommand extends Command {
    public var object:three.js.THREE.Object3D;
    public var materialSlot:Int;
    public var attributeName:String;
    public var oldValue:Int;
    public var newValue:Int;

    public function new(editor:Editor, object:three.js.THREE.Object3D = null, attributeName:String = '', newValue:Int = null, materialSlot:Int = -1) {
        super(editor);

        this.type = 'SetMaterialColorCommand';
        this.name = editor.getString('command/SetMaterialColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material:three.js.THREE.Material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldValue = (material != null) ? material[attributeName].getHex() : null;
        this.newValue = newValue;

        this.attributeName = attributeName;
    }

    public override function execute():Void {
        var material:three.js.THREE.Material = editor.getObjectMaterial(object, materialSlot);

        material[attributeName].setHex(newValue);

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public override function undo():Void {
        var material:three.js.THREE.Material = editor.getObjectMaterial(object, materialSlot);

        material[attributeName].setHex(oldValue);

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public override function update(cmd:SetMaterialColorCommand):Void {
        this.newValue = cmd.newValue;
    }

    public override function toJSON():Dynamic {
        var output:Dynamic = super.toJSON();

        Reflect.setField(output, 'objectUuid', object.uuid);
        Reflect.setField(output, 'attributeName', attributeName);
        Reflect.setField(output, 'oldValue', oldValue);
        Reflect.setField(output, 'newValue', newValue);
        Reflect.setField(output, 'materialSlot', materialSlot);

        return output;
    }

    public override function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        object = editor.objectByUuid(json.objectUuid);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
        materialSlot = json.materialSlot;
    }
}