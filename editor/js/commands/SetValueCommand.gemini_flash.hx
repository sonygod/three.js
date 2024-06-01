package ;

import haxe.DynamicAccess;

class SetValueCommand extends Command {

    public var object(default, null) : DynamicAccess<Dynamic>;
    public var attributeName : String;
    public var oldValue : Dynamic;
    public var newValue : Dynamic;

    public function new(editor : Editor, object : DynamicAccess<Dynamic> = null, attributeName : String = "", newValue : Dynamic = null) {

        super(editor);

        this.type = 'SetValueCommand';
        this.name = editor.strings.getKey('command/SetValue') + ': ' + attributeName;
        this.updatable = true;

        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? Reflect.field(object, attributeName) : null;
        this.newValue = newValue;

    }

    override public function execute() {

        Reflect.setField(this.object, this.attributeName, this.newValue);
        this.editor.signals.objectChanged.dispatch(this.object);
        // this.editor.signals.sceneGraphChanged.dispatch();

    }

    override public function undo() {

        Reflect.setField(this.object, this.attributeName, this.oldValue);
        this.editor.signals.objectChanged.dispatch(this.object);
        // this.editor.signals.sceneGraphChanged.dispatch();

    }

    override public function update(cmd : SetValueCommand) {

        this.newValue = cmd.newValue;

    }

    override public function toJSON() : Dynamic {

        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.attributeName = this.attributeName;
        output.oldValue = this.oldValue;
        output.newValue = this.newValue;

        return output;

    }

    override public function fromJSON(json : Dynamic) {

        super.fromJSON(json);

        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
        this.object = this.editor.objectByUuid(json.objectUuid);

    }

}