import three.core.Object3D;
import three.materials.Material;

class SetMaterialColorCommand extends Command {

    public var object:Object3D;
    public var attributeName:String;
    public var newValue:Int;
    public var oldValue:Int;
    public var materialSlot:Int;

    public function new(editor:Editor, object:Object3D = null, attributeName:String = "", newValue:Int = null, materialSlot:Int = -1) {
        super(editor);

        this.type = 'SetMaterialColorCommand';
        this.name = editor.strings.getKey('command/SetMaterialColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material:Material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldValue = (material != null) ? Std.parseInt(StringTools.replace(material[attributeName].getHexString(), "#", "0x")) : null; // Convert hex string to Int
        this.newValue = newValue;

        this.attributeName = attributeName;
    }

    override public function execute():Void {
        var material:Material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        material[this.attributeName].setHex(this.newValue);

        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    override public function undo():Void {
        var material:Material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        material[this.attributeName].setHex(this.oldValue);

        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    override public function update(cmd:SetMaterialColorCommand):Void {
        this.newValue = cmd.newValue;
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;
        output.materialSlot = this.materialSlot;

        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
        this.materialSlot = json.materialSlot;
    }
}