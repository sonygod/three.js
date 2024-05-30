package;

import js.npm.Command;

class SetMaterialVectorCommand extends Command {
    public var type: String = 'SetMaterialVectorCommand';
    public var name: String;
    public var updatable: Bool;
    public var object: Dynamic;
    public var materialSlot: Int;
    public var oldValue: Array<Float>;
    public var newValue: Array<Float>;
    public var attributeName: String;

    public function new(editor: Dynamic, ?object: Dynamic, attributeName: String, ?newValue: Array<Float>, materialSlot: Int) {
        super(editor);
        $if (object != null) {
            $if (attributeName != '') {
                $if (newValue != null) {
                    $this.name = editor.strings.getKey('command/SetMaterialVector') + ': ' + attributeName;
                    $this.updatable = true;
                    $this.object = object;
                    $this.materialSlot = materialSlot;
                    $var material = $if (object != null) editor.getObjectMaterial(object, materialSlot) else null;
                    $this.oldValue = $if (material != null) material.get_attributeName().toArray() else null;
                    $this.newValue = newValue;
                    $this.attributeName = attributeName;
                }
            }
        }
    }

    public function execute() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material.set_attributeName(newValue);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material.set_attributeName(oldValue);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function update(cmd: SetMaterialVectorCommand) {
        newValue = cmd.newValue;
    }

    public function toJSON(): Dynamic {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;
        output.materialSlot = materialSlot;
        return output;
    }

    public function fromJSON(json: Dynamic) {
        super.fromJSON(json);
        object = editor.objectByUuid(json.objectUuid);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
        materialSlot = json.materialSlot;
    }
}