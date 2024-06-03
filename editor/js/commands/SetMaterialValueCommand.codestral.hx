import Command;
import three.THREE.Object3D;
import three.THREE.Material;

class SetMaterialValueCommand extends Command {

    public var object: Object3D;
    public var attributeName: String;
    public var newValue: Dynamic;
    public var materialSlot: Int;
    public var oldValue: Dynamic;

    public function new(editor: Editor, ?object: Object3D, ?attributeName: String, ?newValue: Dynamic, ?materialSlot: Int) {
        super(editor);

        this.type = 'SetMaterialValueCommand';
        this.name = editor.strings.getKey('command/SetMaterialValue') + ': ' + (attributeName == null ? '' : attributeName);
        this.updatable = true;

        this.object = object == null ? null : object;
        this.materialSlot = materialSlot == null ? -1 : materialSlot;

        var material: Material = (this.object != null) ? editor.getObjectMaterial(this.object, this.materialSlot) : null;
        this.oldValue = (material != null) ? Reflect.field(material, attributeName) : null;
        this.newValue = newValue;

        this.attributeName = attributeName == null ? '' : attributeName;
    }

    @override public function execute(): Void {
        var material: Material = this.editor.getObjectMaterial(this.object, this.materialSlot);
        Reflect.setField(material, this.attributeName, this.newValue);
        material.needsUpdate = true;

        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    @override public function undo(): Void {
        var material: Material = this.editor.getObjectMaterial(this.object, this.materialSlot);
        Reflect.setField(material, this.attributeName, this.oldValue);
        material.needsUpdate = true;

        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    @override public function update(cmd: SetMaterialValueCommand): Void {
        this.newValue = cmd.newValue;
    }

    @override public function toJSON(): Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object == null ? null : this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;
        output.materialSlot = this.materialSlot;

        return output;
    }

    @override public function fromJSON(json: Dynamic): Void {
        super.fromJSON(json);

        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
        this.object = json.objectUuid == null ? null : this.editor.objectByUuid(json.objectUuid);
        this.materialSlot = json.materialSlot;
    }
}