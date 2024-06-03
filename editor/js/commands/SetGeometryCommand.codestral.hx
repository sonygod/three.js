import three.core.Object3D;
import three.core.Geometry;
import three.loaders.ObjectLoader;
import Editor;
import Command;

class SetGeometryCommand extends Command {

    public var type: String = "SetGeometryCommand";
    public var name: String;
    public var updatable: Bool = true;

    public var object: Object3D;
    public var oldGeometry: Geometry;
    public var newGeometry: Geometry;

    public function new(editor: Editor, ?object: Object3D, ?newGeometry: Geometry) {
        super(editor);

        this.name = editor.strings.getKey("command/SetGeometry");

        if (object != null) {
            this.object = object;
            this.oldGeometry = object.geometry;
        }

        if (newGeometry != null) {
            this.newGeometry = newGeometry;
        }
    }

    public function execute(): Void {
        this.object.geometry.dispose();
        this.object.geometry = this.newGeometry;
        this.object.geometry.computeBoundingSphere();

        this.editor.signals.geometryChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo(): Void {
        this.object.geometry.dispose();
        this.object.geometry = this.oldGeometry;
        this.object.geometry.computeBoundingSphere();

        this.editor.signals.geometryChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function update(cmd: SetGeometryCommand): Void {
        this.newGeometry = cmd.newGeometry;
    }

    public function toJSON(): Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.oldGeometry = this.oldGeometry.toJSON();
        output.newGeometry = this.newGeometry.toJSON();

        return output;
    }

    public function fromJSON(json: Dynamic): Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.oldGeometry = parseGeometry(json.oldGeometry);
        this.newGeometry = parseGeometry(json.newGeometry);
    }

    private function parseGeometry(data: Dynamic): Geometry {
        var loader = new ObjectLoader();
        return loader.parseGeometries([data])[data.uuid];
    }
}