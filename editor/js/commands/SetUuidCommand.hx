package three.js.editor.commands;

import three.js.editor.Command;

class SetUuidCommand extends Command {
    private var editor:Editor;
    private var object:Object3D;
    private var oldUuid:String;
    private var newUuid:String;

    public function new(editor:Editor, object:Object3D = null, newUuid:String = null) {
        super(editor);
        this.type = 'SetUuidCommand';
        this.name = editor.strings.getKey('command/SetUuid');

        this.object = object;
        this.oldUuid = (object != null) ? object.uuid : null;
        this.newUuid = newUuid;
    }

    override public function execute():Void {
        object.uuid = newUuid;
        editor.signals.objectChanged.dispatch(object);
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function undo():Void {
        object.uuid = oldUuid;
        editor.signals.objectChanged.dispatch(object);
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON(this);
        output.oldUuid = oldUuid;
        output.newUuid = newUuid;
        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        oldUuid = json.oldUuid;
        newUuid = json.newUuid;
        object = editor.objectByUuid(json.oldUuid);

        if (object == null) {
            object = editor.objectByUuid(json.newUuid);
        }
    }
}