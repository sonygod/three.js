import Command from '../Command.hx';
import ObjectLoader from 'three/src/loaders/ObjectLoader.js';

class AddObjectCommand extends Command {
    public object:Dynamic;
    public var type:String = 'AddObjectCommand';

    public function new(editor, ?object) {
        super(editor);
        this.object = object ?? null;
        if (object != null) {
            this.name = editor.strings.getKey('command/AddObject') + ': ' + Std.string(object.name);
        }
    }

    public function execute() {
        this.editor.addObject(this.object);
        this.editor.select(this.object);
    }

    public function undo() {
        this.editor.removeObject(this.object);
        this.editor.deselect();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.object = this.object.toJSON();
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        this.object = this.editor.objectByUuid(json.object.object.uuid);
        if (this.object == null) {
            var loader = new ObjectLoader();
            this.object = loader.parse(json.object);
        }
    }
}

@:export(AddObjectCommand)