package three.js.editor.js;

class Command {
    public var id:Int = -1;
    public var inMemory:Bool = false;
    public var updatable:Bool = false;
    public var type:String = '';
    public var name:String = '';
    public var editor:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
    }

    public function toJSON():Dynamic {
        var output:Dynamic = {};
        output.type = this.type;
        output.id = this.id;
        output.name = this.name;
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        this.inMemory = true;
        this.type = json.type;
        this.id = json.id;
        this.name = json.name;
    }
}