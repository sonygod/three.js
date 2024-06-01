import three.THREE;

class SetColorCommand extends Command {

    public var object(default, null) : THREE.Object3D;
    public var attributeName(default, null) : String;
    public var oldValue : Int;
    public var newValue : Int;

    public function new(editor : Editor, object : THREE.Object3D = null, attributeName : String = "", newValue : Int = null) {

        super(editor);

        this.type = 'SetColorCommand';
        this.name = editor.strings.getKey('command/SetColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? Reflect.field(object, attributeName).getHex() : null; 
        this.newValue = newValue;
    }

    override public function execute() : Void {
        Reflect.field(this.object, this.attributeName).setHex(this.newValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    override public function undo() : Void {
        Reflect.field(this.object, this.attributeName).setHex(this.oldValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    override public function update(cmd : Command) : Void {
        this.newValue = (cast cmd).newValue; 
    }

    override public function toJSON() : Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;

        return output;
    }

    override public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
    }
}