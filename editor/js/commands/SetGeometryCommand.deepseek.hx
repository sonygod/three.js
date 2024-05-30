import three.Command;
import three.ObjectLoader;

class SetGeometryCommand extends Command {

    public function new(editor:Editor, object:three.Object3D = null, newGeometry:three.Geometry = null) {
        super(editor);

        this.type = 'SetGeometryCommand';
        this.name = editor.strings.getKey('command/SetGeometry');
        this.updatable = true;

        this.object = object;
        this.oldGeometry = (object != null) ? object.geometry : null;
        this.newGeometry = newGeometry;
    }

    public function execute() {
        this.object.geometry.dispose();
        this.object.geometry = this.newGeometry;
        this.object.geometry.computeBoundingSphere();

        this.editor.signals.geometryChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo() {
        this.object.geometry.dispose();
        this.object.geometry = this.oldGeometry;
        this.object.geometry.computeBoundingSphere();

        this.editor.signals.geometryChanged.dispatch(this.object);
        this.editor.signals.sceneGraphChanged.dispatch();
    }

    public function update(cmd:SetGeometryCommand) {
        this.newGeometry = cmd.newGeometry;
    }

    public function toJSON() {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.oldGeometry = this.oldGeometry.toJSON();
        output.newGeometry = this.newGeometry.toJSON();

        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);

        this.oldGeometry = parseGeometry(json.oldGeometry);
        this.newGeometry = parseGeometry(json.newGeometry);

        function parseGeometry(data:Dynamic) {
            var loader = new ObjectLoader();
            return loader.parseGeometries([data])[data.uuid];
        }
    }
}