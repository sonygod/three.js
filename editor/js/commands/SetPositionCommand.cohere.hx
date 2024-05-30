import js.Browser.console;
import js.three.Vector3;

class SetPositionCommand {
    public var type: String;
    public var name: String;
    public var updatable: Bool;
    public var object: Dynamic;
    public var oldPosition: Vector3;
    public var newPosition: Vector3;

    public function new(editor: Dynamic, ?object: Dynamic, ?newPosition: Vector3, ?optionalOldPosition: Vector3) {
        $if (object != null && newPosition != null) {
            $this.oldPosition = object.position.clone();
            $this.newPosition = newPosition.clone();
        }

        $if (optionalOldPosition != null) {
            $this.oldPosition = optionalOldPosition.clone();
        }

        $this.type = 'SetPositionCommand';
        $this.name = editor.strings.getKey('command/SetPosition');
        $this.updatable = true;
        $this.object = object;
    }

    public function execute() {
        $this.object.position.copy($this.newPosition);
        $this.object.updateMatrixWorld(true);
        $this.editor.signals.objectChanged.dispatch($this.object);
    }

    public function undo() {
        $this.object.position.copy($this.oldPosition);
        $this.object.updateMatrixWorld(true);
        $this.editor.signals.objectChanged.dispatch($this.object);
    }

    public function update(command: SetPositionCommand) {
        $this.newPosition.copy(command.newPosition);
    }

    public function toJSON(): Dynamic {
        var output = {
            'objectUuid': $this.object.uuid,
            'oldPosition': $this.oldPosition.toArray(),
            'newPosition': $this.newPosition.toArray()
        };
        return output;
    }

    public function fromJSON(json: Dynamic) {
        $this.object = $this.editor.objectByUuid(json.objectUuid);
        $this.oldPosition = new Vector3().fromArray(json.oldPosition);
        $this.newPosition = new Vector3().fromArray(json.newPosition);
    }
}

class Command {
    public function toJSON(): Dynamic {
        return null;
    }

    public function fromJSON(json: Dynamic) {

    }
}