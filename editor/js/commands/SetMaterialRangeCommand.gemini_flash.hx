import three.core.Object3D;

class SetMaterialRangeCommand extends Command {

    public var object:Object3D;
    public var materialSlot:Int;
    public var oldRange:Array<Dynamic>;
    public var newRange:Array<Dynamic>;
    public var attributeName:String;

    public function new(editor:Editor, object:Object3D = null, attributeName:String = "", newMinValue:Float = -Math.POSITIVE_INFINITY, newMaxValue:Float = Math.POSITIVE_INFINITY, materialSlot:Int = -1) {

        super(editor);

        this.type = 'SetMaterialRangeCommand';
        this.name = editor.strings.getKey('command/SetMaterialRange') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.materialSlot = materialSlot;

        var material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

        this.oldRange = (material != null && Reflect.hasField(material, attributeName)) ? [material.get(attributeName)[0], material.get(attributeName)[1]] : null;
        this.newRange = [newMinValue, newMaxValue];

        this.attributeName = attributeName;

    }

    override public function execute():Void {

        var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        material.set(this.attributeName, this.newRange.copy());
        material.needsUpdate = true;

        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);

    }

    override public function undo():Void {

        var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        material.set(this.attributeName, this.oldRange.copy());
        material.needsUpdate = true;

        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);

    }

    override public function update(cmd:SetMaterialRangeCommand):Void {

        this.newRange = cmd.newRange.copy();

    }

    override public function toJSON():Dynamic {

        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldRange = this.oldRange.copy();
        output.newRange = this.newRange.copy();
        output.materialSlot = this.materialSlot;

        return output;

    }

    override public function fromJSON(json:Dynamic):Void {

        super.fromJSON(json);

        this.attributeName = json.attributeName;
        this.oldRange = json.oldRange.copy();
        this.newRange = json.newRange.copy();
        this.object = this.editor.objectByUuid(json.objectUuid);
        this.materialSlot = json.materialSlot;

    }

}