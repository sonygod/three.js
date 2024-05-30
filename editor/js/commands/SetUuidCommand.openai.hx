package three.js.editor.js.commands;

import three.js.editor.js.Command;

class SetUuidCommand extends Command {
    public var object:ThreeObject3D;
    public var oldUuid:String;
    public var newUuid:String;

    public function new(editor:Editor, ?object:ThreeObject3D, ?newUuid:String) {
        super(editor);
        this.type = 'SetUuidCommand';
        this.name = editor.getString('command/SetUuid');

        this.object = object;
        this.oldUuid = (object != null) ? object.uuid : null;
        this.newUuid = newUuid;
    }

    public function execute():Void {
        this.object.uuid = this.newUuid;
        editor.signals.objectChanged.dispatch(this.object);
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo():Void {
        this.object.uuid = this.oldUuid;
        editor.signals.objectChanged.dispatch(this.object);
        editor.signals.sceneGraphChanged.dispatch();
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
        this.object = editor.getObjectByUuid(json.oldUuid);
        if (this.object == null) {
            this.object = editor.getObjectByUuid(json.newUuid);
        }
    }
}