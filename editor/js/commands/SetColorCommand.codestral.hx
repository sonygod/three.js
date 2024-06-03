import js.html.Console;
import threejs.editor.Command;

class SetColorCommand extends Command {
    public var type:String;
    public var name:String;
    public var updatable:Bool;
    public var object:Dynamic;
    public var attributeName:String;
    public var oldValue:Int;
    public var newValue:Int;

    public function new(editor:Dynamic, object:Dynamic = null, attributeName:String = '', newValue:Int = null) {
        super(editor);

        this.type = 'SetColorCommand';
        this.name = editor.strings.getKey('command/SetColor') + ': ' + attributeName;
        this.updatable = true;
        this.object = object;
        this.attributeName = attributeName;
        this.oldValue = (object != null) ? this.object[this.attributeName].getHex() : null;
        this.newValue = newValue;
    }

    public function execute():Void {
        this.object[this.attributeName].setHex(this.newValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function undo():Void {
        this.object[this.attributeName].setHex(this.oldValue);
        this.editor.signals.objectChanged.dispatch(this.object);
    }

    public function update(cmd:SetColorCommand):Void {
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

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        this.object = this.editor.objectByUuid(json.objectUuid);
        this.attributeName = json.attributeName;
        this.oldValue = json.oldValue;
        this.newValue = json.newValue;
    }
}