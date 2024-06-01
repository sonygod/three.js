import three.Vector3;
import three.Object3D;

class SetPositionCommand extends Command {

    public var object:Object3D;
    public var oldPosition:Vector3;
    public var newPosition:Vector3;

    public function new(editor:Editor, object:Object3D = null, newPosition:Vector3 = null, optionalOldPosition:Vector3 = null) {
        super(editor);

        this.type = 'SetPositionCommand';
        this.name = editor.strings.getKey('command/SetPosition');
        this.updatable = true;

        this.object = object;

        if (object != null && newPosition != null) {
            this.oldPosition = object.position.clone();
            this.newPosition = newPosition.clone();
        }

        if (optionalOldPosition != null) {
            this.oldPosition = optionalOldPosition.clone();
        }
    }

    override public function execute():Void {
        this.object.position.copy(this.newPosition);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    override public function undo():Void {
        this.object.position.copy(this.oldPosition);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    override public function update(command:SetPositionCommand):Void {
        this.newPosition.copy(command.newPosition);
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.oldPosition = this.oldPosition.toArray();
        output.newPosition = this.newPosition.toArray();

        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.object = cast this.editor.objectByUuid(json.objectUuid);
        this.oldPosition = new Vector3().fromArray(json.oldPosition);
        this.newPosition = new Vector3().fromArray(json.newPosition);
    }
}