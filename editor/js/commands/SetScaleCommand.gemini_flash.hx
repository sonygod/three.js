import three.core.Object3D;
import three.math.Vector3;

class SetScaleCommand extends Command {

    public var object:Object3D;
    public var oldScale:Vector3;
    public var newScale:Vector3;

    public function new(editor:Editor, object:Object3D = null, newScale:Vector3 = null, optionalOldScale:Vector3 = null) {

        super(editor);

        this.type = 'SetScaleCommand';
        this.name = editor.strings.getKey('command/SetScale');
        this.updatable = true;

        this.object = object;

        if (object != null && newScale != null) {
            this.oldScale = object.scale.clone();
            this.newScale = newScale.clone();
        }

        if (optionalOldScale != null) {
            this.oldScale = optionalOldScale.clone();
        }
    }

    override public function execute():Void {
        this.object.scale.copy(this.newScale);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    override public function undo():Void {
        this.object.scale.copy(this.oldScale);
        this.object.updateMatrixWorld(true);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    override public function update(command:SetScaleCommand):Void {
        this.newScale.copy(command.newScale);
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.oldScale = this.oldScale.toArray();
        output.newScale = this.newScale.toArray();

        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.oldScale = new Vector3().fromArray(json.oldScale);
        this.newScale = new Vector3().fromArray(json.newScale);
    }
}