import Command from '../Command.hx';

class SetColorCommand extends Command {
    public var object:Object3D;
    public var attributeName:String;
    public var oldValue:Int;
    public var newValue:Int;

    public function new(editor:Editor, ?object:Object3D, ?attributeName:String, ?newValue:Int) {
        super(editor);

        this.type = 'SetColorCommand';
        this.name = editor.strings.getKey('command/SetColor') + ': ' + attributeName;
        this.updatable = true;

        this.object = object ?? null;
        this.attributeName = attributeName ?? '';
        this.oldValue = if (object != null) object.get_attributeName().getHex() else null;
        this.newValue = newValue ?? null;
    }

    public function execute() {
        this.object.set_attributeName(this.newValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function undo() {
        this.object.set_attributeName(this.oldValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function update(cmd:SetColorCommand) {
        this.newValue = cmd.newValue;
    }

    public function toJSON():HashMap<String, Dynamic, String> {
        var output = super.toJSON();
        $set(output, 'objectUuid', this.object.uuid);
        $set(output, 'attributeName', this.attributeName);
        $set(output, 'oldValue', this.oldValue);
        $set(output, 'newValue', this.newValue);
        return output;
    }

    public function fromJSON(json:HashMap<String, Dynamic, String>) {
        super.fromJSON(json);
        this.object = this.editor.objectByUuid(json.objectUuid);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
    }
}

class Object3D {
    public function get_attributeName():Int {
        return 0;
    }

    public function set_attributeName(value:Int):Void {}
}

class Editor {
    public function objectByUuid(uuid:String):Object3D {
        return null;
    }
}

class HashMap<K:String, V:Dynamic, A:String> {
    public function new(?default:V, ?positive:Bool) {}

    public function set(key:K, value:V):V @:never {}
}

class Dynamic {}

class Bool {}

class Int {}

class String {}

class Void {}

class Cmd extends SetColorCommand {}

class Strings {}