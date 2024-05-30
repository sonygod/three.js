import Command from '../Command.hx';
import Euler from 'three/src/math/Euler.hx';

class SetRotationCommand extends Command {
    public var object:Object3D;
    public var oldRotation:Euler;
    public var newRotation:Euler;

    public function new(editor:Editor, ?object:Object3D, ?newRotation:Euler, ?optionalOldRotation:Euler) {
        super(editor);

        $type = 'SetRotationCommand';
        $name = editor.strings.getKey('command/SetRotation');
        $updatable = true;

        $object = object;

        if (object != null && newRotation != null) {
            $oldRotation = object.rotation.clone();
            $newRotation = newRotation.clone();
        }

        if (optionalOldRotation != null) {
            $oldRotation = optionalOldRotation.clone();
        }
    }

    public function execute() {
        $object.rotation.copy($newRotation);
        $object.updateMatrixWorld(true);
        $editor.signals.objectChanged.dispatch($object);
    }

    public function undo() {
        $object.rotation.copy($oldRotation);
        $object.updateMatrixWorld(true);
        $editor.signals.objectChanged.dispatch($object);
    }

    public function update(command:SetRotationCommand) {
        $newRotation.copy(command.newRotation);
    }

    public function toJSON():Map<String, Dynamic> {
        var output = super.toJSON();

        output.set('objectUuid', $object.uuid);
        output.set('oldRotation', $oldRotation.toArray());
        output.set('newRotation', $newRotation.toArray());

        return output;
    }

    public function fromJSON(json:Map<String, Dynamic>) {
        super.fromJSON(json);

        $object = $editor.objectByUuid(json.get('objectUuid'));
        $oldRotation = Euler.fromArray(json.get('oldRotation'));
        $newRotation = Euler.fromArray(json.get('newRotation'));
    }
}

class SetRotationCommandModule {
    public static function get SetRotationCommand() {
        return SetRotationCommand;
    }
}