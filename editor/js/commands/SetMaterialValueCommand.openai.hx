package three.js.editor.commands;

import three.js.editor.commands.Command;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param attributeName String
 * @param newValue Float, String, Bool or Dynamic
 */
class SetMaterialValueCommand extends Command {

    public var object:three.js.THREE.Object3D;
    public var materialSlot:Int;
    public var attributeName:String;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;

    public function new(editor:Editor, object=null, attributeName='', newValue=null, materialSlot=-1) {
        super(editor);
        this.type = 'SetMaterialValueCommand';
        this.name = editor.strings.getKey('command/SetMaterialValue') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material:(object !== null) ? editor.getObjectMaterial(object, materialSlot) : null;
        this.oldValue = (material !== null) ? material[attributeName] : null;
        this.newValue = newValue;

        this.attributeName = attributeName;
    }

    override public function execute() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material[attributeName] = newValue;
        material.needsUpdate = true;

        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    override public function undo() {
        var material = editor.getObjectMaterial(object, materialSlot);
        material[attributeName] = oldValue;
        material.needsUpdate = true;

        editor.signals.objectChanged.dispatch(object);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function update(cmd:SetMaterialValueCommand) {
        newValue = cmd.newValue;
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON(this);
        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;
        output.materialSlot = materialSlot;
        return output;
    }

    override public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
        object = editor.objectByUuid(json.objectUuid);
        materialSlot = json.materialSlot;
    }
}