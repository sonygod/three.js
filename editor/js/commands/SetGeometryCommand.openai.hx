package three.js.editor.js.commands;

import three.js.editor.Command;
import three.ObjectLoader;

class SetGeometryCommand extends Command {

    public var type:String;
    public var name:String;
    public var updatable:Bool;

    public var object:three.Object3D;
    public var oldGeometry:three.Geometry;
    public var newGeometry:three.Geometry;

    public function new(editor:Editor, object:three.Object3D = null, newGeometry:three.Geometry = null) {
        super(editor);

        type = 'SetGeometryCommand';
        name = editor.strings.getKey('command/SetGeometry');
        updatable = true;

        this.object = object;
        if (object != null) {
            oldGeometry = object.geometry;
        } else {
            oldGeometry = null;
        }
        this.newGeometry = newGeometry;
    }

    override public function execute():Void {
        object.geometry.dispose();
        object.geometry = newGeometry;
        object.geometry.computeBoundingSphere();

        editor.signals.geometryChanged.dispatch(object);
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function undo():Void {
        object.geometry.dispose();
        object.geometry = oldGeometry;
        object.geometry.computeBoundingSphere();

        editor.signals.geometryChanged.dispatch(object);
        editor.signals.sceneGraphChanged.dispatch();
    }

    override public function update(cmd:SetGeometryCommand):Void {
        newGeometry = cmd.newGeometry;
    }

    override public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.oldGeometry = oldGeometry.toJSON();
        output.newGeometry = newGeometry.toJSON();
        return output;
    }

    override public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        object = editor.objectByUuid(json.objectUuid);
        oldGeometry = parseGeometry(json.oldGeometry);
        newGeometry = parseGeometry(json.newGeometry);
    }

    private function parseGeometry(data:Dynamic):three.Geometry {
        var loader = new ObjectLoader();
        return loader.parseGeometries([data])[data.uuid];
    }
}