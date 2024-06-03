import Command from '../Command';
import Editor from '../Editor';
import THREE.Object3D from 'three.js.Object3D';
import THREE.Material from 'three.js.Material';

class SetMaterialColorCommand extends Command {

    public var object: THREE.Object3D;
    public var attributeName: String;
    public var newValue: Int;
    public var materialSlot: Int;
    public var oldValue: Int;

    public function new(editor: Editor, ?object: THREE.Object3D = null, ?attributeName: String = '', ?newValue: Int = null, ?materialSlot: Int = -1) {
        super(editor);

        this.type = 'SetMaterialColorCommand';
        this.name = editor.strings.getKey('command/SetMaterialColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material: THREE.Material = (object !== null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldValue = (material !== null) ? material.getHex(Reflect.field(material, attributeName)) : null;
        this.newValue = newValue;

        this.attributeName = attributeName;
    }

    public function execute(): Void {
        var material: THREE.Material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        material.setHex(Reflect.field(material, this.attributeName), this.newValue);

        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    public function undo(): Void {
        var material: THREE.Material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        material.setHex(Reflect.field(material, this.attributeName), this.oldValue);

        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    public function update(cmd: SetMaterialColorCommand): Void {
        this.newValue = cmd.newValue;
    }

    public function toJSON(): Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;
        output.materialSlot = this.materialSlot;

        return output;
    }

    public function fromJSON(json: Dynamic): Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
        this.materialSlot = json.materialSlot;
    }
}