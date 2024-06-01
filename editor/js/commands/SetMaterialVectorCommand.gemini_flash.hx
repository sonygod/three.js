import haxe.Json;

class SetMaterialVectorCommand extends Command {

    public var object(default, null):Dynamic;
    public var materialSlot:Int;
    public var oldValue:Array<Float>;
    public var newValue:Array<Float>;
    public var attributeName:String;

    public function new(editor:Dynamic, object:Dynamic = null, attributeName:String = "", newValue:Array<Float> = null, materialSlot:Int = -1) {
        super(editor);

        this.type = "SetMaterialVectorCommand";
        this.name = editor.strings.getKey("command/SetMaterialVector") + ": " + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldValue = (material != null) ? material[attributeName].toArray() : null;
        this.newValue = newValue;

        this.attributeName = attributeName;
    }

    override public function execute():Void {
        var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
        material[this.attributeName].fromArray(this.newValue);
        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    override public function undo():Void {
        var material = this.editor.getObjectMaterial(this.object, this.materialSlot);
        material[this.attributeName].fromArray(this.oldValue);
        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    override public function update(cmd:Dynamic):Void {
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