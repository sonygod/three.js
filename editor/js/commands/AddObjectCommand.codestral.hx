@:fileContent("Command.hx")
class Command {
    public function new(editor:Editor) {
        // Constructor code here
    }

    public function toJSON():Dynamic {
        // toJSON implementation here
        return { };
    }

    public function fromJSON(json:Dynamic) {
        // fromJSON implementation here
    }
}

@:fileContent("ObjectLoader.hx")
class ObjectLoader {
    public function parse(json:Dynamic):Object3D {
        // parse implementation here
        return null;
    }
}

@:fileContent("Editor.hx")
class Editor {
    public var strings:Dynamic;

    public function addObject(object:Object3D) {
        // addObject implementation here
    }

    public function removeObject(object:Object3D) {
        // removeObject implementation here
    }

    public function select(object:Object3D) {
        // select implementation here
    }

    public function deselect() {
        // deselect implementation here
    }

    public function objectByUuid(uuid:String):Object3D {
        // objectByUuid implementation here
        return null;
    }
}

@:fileContent("Object3D.hx")
class Object3D {
    public var name:String;

    public function toJSON():Dynamic {
        // toJSON implementation here
        return { };
    }
}

class AddObjectCommand extends Command {
    public var type:String;
    public var object:Object3D;
    public var name:String;

    public function new(editor:Editor, object:Object3D = null) {
        super(editor);

        this.type = 'AddObjectCommand';
        this.object = object;

        if (this.object != null) {
            this.name = editor.strings.getKey('command/AddObject') + ': ' + this.object.name;
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

    override public function toJSON():Dynamic {
        var output = super.toJSON();
        output.object = this.object.toJSON();
        return output;
    }

    override public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        this.object = this.editor.objectByUuid(json.object.object.uuid);

        if (this.object == null) {
            var loader = new ObjectLoader();
            this.object = loader.parse(json.object);
        }
    }
}