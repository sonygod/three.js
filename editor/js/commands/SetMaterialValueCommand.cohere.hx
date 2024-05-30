package;

import js.Command;

class SetMaterialValueCommand extends Command {
    public var object:Dynamic;
    public var materialSlot:Int;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;
    public var attributeName:String;

    public function new(editor:Dynamic, ?object:Dynamic, ?attributeName:String, ?newValue:Dynamic, ?materialSlot:Int) {
        super(editor);

        $type = 'SetMaterialValueCommand';
        $name = editor.strings.getKey('command/SetMaterialValue') + ': ' + attributeName;
        $updatable = true;

        $object = object;
        $materialSlot = materialSlot;

        var material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        $oldValue = (material != null) ? material[attributeName] : null;
        $newValue = newValue;

        $attributeName = attributeName;
    }

    public function execute() {
        var material = editor.getObjectMaterial(object, materialSlot);

        material[attributeName] = newValue;
        material.needsUpdate = true;

        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo() {
        var material = editor.getObjectMaterial(object, materialSlot);

        material[attributeName] = oldValue;
        material.needsUpdate = true;

        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function update(cmd:SetMaterialValueCommand) {
        newValue = cmd.newValue;
    }

    public function toJSON() {
        var output = super.toJSON();

        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;
        output.materialSlot = materialSlot;

        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);

        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
        object = editor.objectByUuid(json.objectUuid);
        materialSlot = json.materialSlot;
    }
}