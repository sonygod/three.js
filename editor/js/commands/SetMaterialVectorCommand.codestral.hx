import Command;

class SetMaterialVectorCommand extends Command {

    public var object:Dynamic;
    public var materialSlot:Int;
    public var attributeName:String;
    public var oldValue:Array<Float>;
    public var newValue:Array<Float>;

    public function new(editor:Dynamic, ?object:Dynamic, ?attributeName:String, ?newValue:Array<Float>, ?materialSlot:Int) {
        super(editor);

        this.type = 'SetMaterialVectorCommand';
        this.name = editor.strings.getKey('command/SetMaterialVector') + ': ' + attributeName;
        this.updatable = true;

        this.object = object != null ? object : null;
        this.materialSlot = materialSlot != null ? materialSlot : -1;

        var material = (object != null) ? editor.getObjectMaterial(object, this.materialSlot) : null;

        this.oldValue = (material != null) ? material[attributeName].toArray() : null;
        this.newValue = newValue != null ? newValue : null;

        this.attributeName = attributeName != null ? attributeName : '';
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

    public function update(cmd:SetMaterialVectorCommand):Void {
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