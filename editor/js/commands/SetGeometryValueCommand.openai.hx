package three.js.editor.js.commands;

import three.js.editor.js.commands.Command;

class SetGeometryValueCommand extends Command {
    public var object:js.three.Object3D;
    public var attributeName:String;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;

    public function new(editor:Editor, object:js.three.Object3D = null, attributeName:String = '', newValue:Dynamic = null) {
        super(editor);

        this.type = 'SetGeometryValueCommand';
        this.name = editor.getStrings().getKey('command/SetGeometryValue') + ': ' + attributeName;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? object.geometry[attributeName] : null;
        this.newValue = newValue;
    }

    public function execute() {
        object.geometry[attributeName] = newValue;
        editor.signals.objectChanged.dispatch(object);
        editor.signals.geometryChanged.dispatch();
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo() {
        object.geometry[attributeName] = oldValue;
        editor.signals.objectChanged.dispatch(object);
        editor.signals.geometryChanged.dispatch();
        editor.signals.sceneGraphChanged.dispatch();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);

        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;

        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);

        object = editor.getObjectByUuid(json.objectUuid);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
    }
}