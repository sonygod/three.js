package;

/**
 * @param editor pointer to main editor object used to initialize
 *        each command object with a reference to the editor
 */
class Command {

	public var id:Int;
	public var inMemory:Bool;
	public var updatable:Bool;
	public var type:String;
	public var name:String;
	public var editor:Dynamic;

	public function new(editor:Dynamic) {
		this.id = -1;
		this.inMemory = false;
		this.updatable = false;
		this.type = "";
		this.name = "";
		this.editor = editor;
	}

	public function toJSON():Dynamic {
		return {
			type: this.type,
			id: this.id,
			name: this.name
		};
	}

	public function fromJSON(json:Dynamic):Void {
		this.inMemory = true;
		this.type = json.type;
		this.id = json.id;
		this.name = json.name;
	}
}