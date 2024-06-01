import three.core.Object3D;
import three.core.Geometry;
import three.loaders.ObjectLoader;
import js.Lib;

class SetGeometryCommand extends Command {

    public var object(default, null) : Object3D;
    public var oldGeometry(default, null) : Geometry;
    public var newGeometry(default, null) : Geometry;

    public function new(editor : Editor, object : Object3D = null, newGeometry : Geometry = null) {
        super(editor);

        this.type = 'SetGeometryCommand';
        this.name = editor.strings.getKey('command/SetGeometry');
        this.updatable = true;

        this.object = object;
        this.oldGeometry = (object != null) ? object.geometry : null;
        this.newGeometry = newGeometry;
    }

    override public function execute() : Void {
        this.object.geometry.dispose();
        this.object.geometry = this.newGeometry;
        this.object.geometry.computeBoundingSphere();

        this.editor.signals.geometryChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    override public function undo() : Void {
        this.object.geometry.dispose();
        this.object.geometry = this.oldGeometry;
        this.object.geometry.computeBoundingSphere();

        this.editor.signals.geometryChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    override public function update(cmd : Dynamic) : Void {
        var cmd : SetGeometryCommand = cast cmd; // Explicitly cast for type safety
        this.newGeometry = cmd.newGeometry;
    }

    override public function toJSON() : Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.oldGeometry = this.oldGeometry.toJSON();
        output.newGeometry = this.newGeometry.toJSON();

        return output;
    }

    override public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);

        this.oldGeometry = parseGeometry(json.oldGeometry);
        this.newGeometry = parseGeometry(json.newGeometry);

        function parseGeometry(data : Dynamic) : Geometry {
            var loader = new ObjectLoader();
            return cast loader.parseGeometries([data])[data.uuid];
        }
    }
}