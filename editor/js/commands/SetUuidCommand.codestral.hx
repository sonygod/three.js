import Command from '../Command';
import Editor from '../Editor';
import Object3D from 'three.js.Object3D';

class SetUuidCommand extends Command {

    public var object:Object3D;
    public var oldUuid:String;
    public var newUuid:String;

    public function new(editor:Editor, object:Object3D = null, newUuid:String = null) {
        super(editor);

        this.type = 'SetUuidCommand';
        this.name = editor.strings.getKey('command/SetUuid');

        this.object = object;

        this.oldUuid = (object !== null) ? object.uuid : null;
        this.newUuid = newUuid;
    }

    public function execute():Void {
        this.object.uuid = this.newUuid;
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo():Void {
        this.object.uuid = this.oldUuid;
        this.editor.signals.objectChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.oldUuid = this.oldUuid;
        output.newUuid = this.newUuid;
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        this.oldUuid = json.oldUuid;
        this.newUuid = json.newUuid;
        this.object = this.editor.objectByUuid(json.oldUuid);

        if (this.object === undefined) {
            this.object = this.editor.objectByUuid(json.newUuid);
        }
    }
}