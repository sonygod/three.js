import three.THREE;

class SetGeometryValueCommand extends Command {

    public var object(default, null) : THREE.Object3D;
    public var attributeName : String;
    public var oldValue : Dynamic;
    public var newValue : Dynamic;

    /**
     * @param editor Editor
     * @param object THREE.Object3D
     * @param attributeName string
     * @param newValue number, string, boolean or object
     * @constructor
     */
    public function new(editor : Editor, object : THREE.Object3D = null, attributeName : String = "", newValue : Dynamic = null) {

        super(editor);

        this.type = 'SetGeometryValueCommand';
        this.name = editor.strings.getKey('command/SetGeometryValue') + ': ' + attributeName;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? Reflect.field(object.geometry, attributeName) : null;
        this.newValue = newValue;

    }

    override public function execute() {

        Reflect.setField(this.object.geometry, this.attributeName, this.newValue);
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.geometryChanged.dispatch();
        this.editor.signals.sceneGraphChanged.dispatch();

    }

    override public function undo() {

        Reflect.setField(this.object.geometry, this.attributeName, this.oldValue);
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.geometryChanged.dispatch();
        this.editor.signals.sceneGraphChanged.dispatch();

    }

    override public function toJSON() : Dynamic {

        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;

        return output;

    }

    override public function fromJSON(json : Dynamic) {

        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;

    }

}