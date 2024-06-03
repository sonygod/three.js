class Command {
    public var id: Int = -1;
    public var inMemory: Bool = false;
    public var updatable: Bool = false;
    public var type: String = '';
    public var name: String = '';
    public var editor: Editor;

    public function new(editor: Editor) {
        this.editor = editor;
    }

    public function toJSON(): Dynamic {
        var output = {
            type: this.type,
            id: this.id,
            name: this.name
        };
        return output;
    }

    public function fromJSON(json: Dynamic) {
        this.inMemory = true;
        this.type = json.type;
        this.id = json.id;
        this.name = json.name;
    }
}