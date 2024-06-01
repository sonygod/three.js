import three.core.Object3D;

class SetMaterialValueCommand extends Command {
  
  public var object:Object3D;
  public var materialSlot:Int;
  public var attributeName:String;
  public var oldValue:Dynamic;
  public var newValue:Dynamic;

  /**
   * @param editor Editor
   * @param object THREE.Object3D
   * @param attributeName string
   * @param newValue number, string, boolean or object
   * @constructor
   */
  public function new(editor:Editor, object:Object3D = null, attributeName:String = "", newValue:Dynamic = null, materialSlot:Int = -1) {
    super(editor);

    this.type = "SetMaterialValueCommand";
    this.name = editor.strings.getKey("command/SetMaterialValue") + ": " + attributeName;
    this.updatable = true;

    this.object = object;
    this.materialSlot = materialSlot;

    var material = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

    this.oldValue = (material != null) ? Reflect.field(material, attributeName) : null;
    this.newValue = newValue;

    this.attributeName = attributeName;
  }

  override public function execute():Void {
    var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

    Reflect.setField(material, this.attributeName, this.newValue);
    material.needsUpdate = true;

    this.editor.signals.objectChanged.dispatch(this.object);
    this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
  }

  override public function undo():Void {
    var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

    Reflect.setField(material, this.attributeName, this.oldValue);
    material.needsUpdate = true;

    this.editor.signals.objectChanged.dispatch(this.object);
    this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
  }

  override public function update(cmd:SetMaterialValueCommand):Void {
    this.newValue = cmd.newValue;
  }

  override public function toJSON():Dynamic {
    var output = super.toJSON();

    Reflect.setField(output, "objectUuid", this.object.uuid);
    Reflect.setField(output, "attributeName", this.attributeName);
    Reflect.setField(output, "oldValue", this.oldValue);
    Reflect.setField(output, "newValue", this.newValue);
    Reflect.setField(output, "materialSlot", this.materialSlot);

    return output;
  }

  override public function fromJSON(json:Dynamic):Void {
    super.fromJSON(json);

    this.attributeName = Reflect.field(json, "attributeName");
    this.oldValue = Reflect.field(json, "oldValue");
    this.newValue = Reflect.field(json, "newValue");
    this.object = cast this.editor.objectByUuid(Reflect.field(json, "objectUuid")), Object3D;
    this.materialSlot = Reflect.field(json, "materialSlot");
  }
}