import js.js_ver.Command;

class SetMaterialRangeCommand extends Command {
    public var type:String;
    public var name:String;
    public var updatable:Bool;
    public var object:Dynamic;
    public var materialSlot:Int;
    public var oldRange:Array<Float>;
    public var newRange:Array<Float>;
    public var attributeName:String;

    public function new(editor:Dynamic, ?object:Dynamic, attributeName:String = "", newMinValue:Float = -Infinity, newMaxValue:Float = Infinity, materialSlot:Int = -1) {
        super(editor);
        $type = "SetMaterialRangeCommand";
        $name = editor.strings.getKey("command/SetMaterialRange") + ": " + attributeName;
        $updatable = true;
        $object = object;
        $materialSlot = materialSlot;
        var material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;
        $oldRange = (material != null && material.hasOwnProperty(attributeName)) ? material[attributeName].slice() : null;
        $newRange = [newMinValue, newMaxValue];
        $attributeName = attributeName;
    }

    public function execute() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material[attributeName] = newRange.slice();
        material.needsUpdate = true;
        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material[attributeName] = oldRange.slice();
        material.needsUpdate = true;
        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function update(cmd:SetMaterialRangeCommand) {
        $newRange = cmd.newRange.slice();
    }

    public function toJSON() {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldRange = oldRange.slice();
        output.newRange = newRange.slice();
        output.materialSlot = materialSlot;
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        $attributeName = json.attributeName;
        $oldRange = json.oldRange.slice();
        $newRange = json.newRange.slice();
        $object = editor.objectByUuid(json.objectUuid);
        $materialSlot = json.materialSlot;
    }
}

class js {
    static class js_ver {
        static class Command { }
    }
}