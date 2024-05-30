import Command from '../Command.hx';

class SetValueCommand extends Command {
    public var object:Dynamic;
    public var attributeName:String;
    public var oldValue:Dynamic;
    public var newValue:Dynamic;

    public function new(editor:Dynamic, ?object:Dynamic, attributeName:String, newValue:Dynamic) {
        super(editor);

        this.type = 'SetValueCommand';
        this.name = editor.strings.getKey('command/SetValue') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? Reflect.field(object, attributeName) : null;
        this.newValue = newValue;
    }

    public function execute() {
        Reflect.setField(this.object, this.attributeName, this.newValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function undo() {
        Reflect.setField(this.object, this.attributeName, this.oldValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function update(cmd:SetValueCommand) {
        this.newValue = cmd.newValue;
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
        this.object = this.editor.objectByUuid(json.objectUuid);
    }
}

class DynamicAccess {
    public static function setField(obj:Dynamic, field:String, value:Dynamic) {
        Reflect.setField(obj, field, value);
    }
}