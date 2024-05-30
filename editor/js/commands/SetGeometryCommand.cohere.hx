import Command from '../Command.hx';
import ObjectLoader from 'three/src/loaders/ObjectLoader.js';

class SetGeometryCommand extends Command {
    public var object:Null<Dynamic> = null;
    public var oldGeometry:Null<Dynamic> = null;
    public var newGeometry:Null<Dynamic> = null;

    public function new(editor:Dynamic, ?object:Dynamic, ?newGeometry:Dynamic) {
        super(editor);

        $type = 'SetGeometryCommand';
        $name = editor.strings.getKey('command/SetGeometry');
        $updatable = true;

        $object = object;
        if ($object != null) {
            $oldGeometry = Reflect.field($object, 'geometry');
        }
        $newGeometry = newGeometry;
    }

    public function execute() {
        $object.geometry.dispose();
        $object.geometry = $newGeometry;
        $object.geometry.computeBoundingSphere();

        $editor.signals.geometryChanged.dispatch($object);
        $editor.signals.sceneGraphChanged.dispatch();
    }

    public function undo() {
        $object.geometry.dispose();
        $object.geometry = $oldGeometry;
        $object.geometry.computeBoundingSphere();

        $editor.signals.geometryChanged.dispatch($object);
        $editor.signals.sceneGraphChanged.dispatch();
    }

    public function update(cmd:SetGeometryCommand) {
        $newGeometry = cmd.newGeometry;
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = $object.uuid;
        output.oldGeometry = $oldGeometry.toJSON();
        output.newGeometry = $newGeometry.toJSON();
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);

        $object = $editor.objectByUuid(json.objectUuid);
        $oldGeometry = parseGeometry(json.oldGeometry);
        $newGeometry = parseGeometry(json.newGeometry);

        function parseGeometry(data:Dynamic):Dynamic {
            var loader = new ObjectLoader();
            return Reflect.field(loader.parseGeometries([data]), data.uuid);
        }
    }
}

export { SetGeometryCommand };