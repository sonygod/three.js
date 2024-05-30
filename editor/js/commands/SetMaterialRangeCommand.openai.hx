package three.js.editor.commands;

import three.js.editor.Command;

class SetMaterialRangeCommand extends Command {
    public var object : THREE.Object3D;
    public var materialSlot : Int;
    public var attributeName : String;
    public var oldRange : Array<Float>;
    public var newRange : Array<Float>;

    public function new(editor : Editor, object : THREE.Object3D = null, attributeName : String = '', newMinValue : Float = -Math.POSITIVE_INFINITY, newMaxValue : Float = Math.POSITIVE_INFINITY, materialSlot : Int = -1) {
        super(editor);

        this.type = 'SetMaterialRangeCommand';
        this.name = editor.strings.getKey('command/SetMaterialRange') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material : Dynamic = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldRange = (material != null && material[attributeName] != null) ? material[attributeName].copy() : null;
        this.newRange = [newMinValue, newMaxValue];

        this.attributeName = attributeName;
    }

    public function execute() : Void {
        var material : Dynamic = editor.getObjectMaterial(object, materialSlot);

        material[attributeName] = newRange.copy();
        material.needsUpdate = true;

        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo() : Void {
        var material : Dynamic = editor.getObjectMaterial(object, materialSlot);

        material[attributeName] = oldRange.copy();
        material.needsUpdate = true;

        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function update(cmd : SetMaterialRangeCommand) : Void {
        newRange = cmd.newRange.copy();
    }

    public function toJSON() : Dynamic {
        var output : Dynamic = super.toJSON();

        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldRange = oldRange.copy();
        output.newRange = newRange.copy();
        output.materialSlot = materialSlot;

        return output;
    }

    public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);

        attributeName = json.attributeName;
        oldRange = json.oldRange.copy();
        newRange = json.newRange.copy();
        object = editor.objectByUuid(json.objectUuid);
        materialSlot = json.materialSlot;
    }
}