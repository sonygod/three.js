import three.core.Object3D;

class SetUuidCommand extends Command {

    public var object:Object3D;
    public var oldUuid:String;
    public var newUuid:String;

    public function new(editor:Editor, object:Object3D = null, newUuid:String = null) {

        super(editor);

        this.type = 'SetUuidCommand';
        this.name = editor.strings.getKey('command/SetUuid');

        this.object = object;

        this.oldUuid = (object != null) ? object.uuid : null;
        this.newUuid = newUuid;

    }

    override public function execute():Void {

        this.object.uuid = this.newUuid;
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();

    }

    override public function undo():Void {

        this.object.uuid = this.oldUuid;
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();

    }

    override public function toJSON():Dynamic {

        var output = super.toJSON();

        Reflect.setField(output, "oldUuid", this.oldUuid);
        Reflect.setField(output, "newUuid", this.newUuid);

        return output;

    }

    override public function fromJSON(json:Dynamic):Void {

        super.fromJSON(json);

        this.oldUuid = Reflect.field(json, "oldUuid");
        this.newUuid = Reflect.field(json, "newUuid");
        this.object = this.editor.objectByUuid(this.oldUuid);

        if (this.object == null) {

            this.object = this.editor.objectByUuid(this.newUuid);

        }

    }

}