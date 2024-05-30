import three.js.editor.js.commands.Command;
import three.ObjectLoader;

class AddObjectCommand extends Command {

	public function new(editor:Editor, object:three.Object3D = null) {
		super(editor);
		this.type = 'AddObjectCommand';
		this.object = object;
		if (object !== null) {
			this.name = editor.strings.getKey('command/AddObject') + ': ' + object.name;
		}
	}

	public function execute():Void {
		this.editor.addObject(this.object);
		this.editor.select(this.object);
	}

	public function undo():Void {
		this.editor.removeObject(this.object);
		this.editor.deselect();
	}

	public function toJSON():Dynamic {
		var output = super.toJSON();
		output.object = this.object.toJSON();
		return output;
	}

	public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);
		this.object = this.editor.objectByUuid(json.object.object.uuid);
		if (this.object == null) {
			var loader = new ObjectLoader();
			this.object = loader.parse(json.object);
		}
	}
}