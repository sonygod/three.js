class Command {
    var id:Int;
    var inMemory:Bool;
    var updatable:Bool;
    var type:String;
    var name:String;
    var editor;

    public function new(editor) {
        this.id = -1;
        this.inMemory = false;
        this.updatable = false;
        this.type = "";
        this.name = "";
        this.editor = editor;
    }

    function toJSON():String {
        var output = {
            'type': type,
            'id': id,
            'name': name
        };
        return Std.string(Json.stringify(output));
    }

    function fromJSON(json:String) {
        inMemory = true;
        var data = Json.parse(json);
        type = data.type;
        id = data.id;
        name = data.name;
    }
}