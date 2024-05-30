package three.js.editor.js.commands;

import three.js.editor.Command;
import three.ObjectLoader;

class AddObjectCommand extends Command {
    public var editor:Editor;
    public var object:three.Object3D;
    public var name:String;

    public function new(editor:Editor, object:three.Object3D = null) {
        super(editor);
        this.type = 'AddObjectCommand';
        this.object = object;
        if (object != null) {
            this.name = editor.strings.getKey('command/AddObject') + ': ' + object.name;
        }
    }

    public function execute() {
        editor.addObject(object);
        editor.select(object);
    }

    public function undo() {
        editor.removeObject(object);
        editor.deselect();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.object = object.toJSON();
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        object = editor.objectByUuid(json.object.object.uuid);
        if (object == null) {
            var loader = new ObjectLoader();
            object = loader.parse(json.object);
        }
    }
}