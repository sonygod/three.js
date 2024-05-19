package three.editor.commands;

import three.editor.Command;

class SetGeometryValueCommand extends Command {
    
    public var object:three.Object3D;
    public var attributeName:String;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;

    public function new(editor:Editor, object:three.Object3D = null, attributeName:String = "", newValue:Dynamic = null) {
        super(editor);
        this.type = 'SetGeometryValueCommand';
        this.name = editor.getString('command/SetGeometryValue') + ': ' + attributeName;
        
        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? object.geometry.get(attributeName) : null;
        this.newValue = newValue;
    }

    override public function execute():Void {
        object.geometry.set(attributeName, newValue);
        editor.signals.objectChanged.dispatch(object);
        editor.signals.geometryChanged.dispatch();
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function undo():Void {
        object.geometry.set(attributeName, oldValue);
        editor.signals.objectChanged.dispatch(object);
        editor.signals.geometryChanged.dispatch();
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.attributeName = attributeName;
        output.oldValue = oldValue;
        output.newValue = newValue;
        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        object = editor.getObjectByUuid(json.objectUuid);
        attributeName = json.attributeName;
        oldValue = json.oldValue;
        newValue = json.newValue;
    }
}