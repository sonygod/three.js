import three.js.editor.js.commands.Command;
import three.js.ObjectLoader;

class RemoveObjectCommand extends Command {

	public function new(editor:Editor, object:three.js.Object3D = null) {
		super(editor);

		this.type = 'RemoveObjectCommand';

		this.object = object;
		this.parent = (object !== null) ? object.parent : null;

		if (this.parent !== null) {
			this.index = Std.indexOf(this.parent.children, this.object);
		}

		if (object !== null) {
			this.name = editor.strings.getKey('command/RemoveObject') + ': ' + object.name;
		}
	}

	public function execute():Void {
		this.editor.removeObject(this.object);
		this.editor.deselect();
	}

	public function undo():Void {
		this.editor.addObject(this.object, this.parent, this.index);
		this.editor.select(this.object);
	}

	public function toJSON():Dynamic {
		var output = super.toJSON();

		output.object = this.object.toJSON();
		output.index = this.index;
		output.parentUuid = this.parent.uuid;

		return output;
	}

	public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.parent = this.editor.objectByUuid(json.parentUuid);
		if (this.parent === null) {
			this.parent = this.editor.scene;
		}

		this.index = json.index;

		this.object = this.editor.objectByUuid(json.object.object.uuid);

		if (this.object === null) {
			var loader = new ObjectLoader();
			this.object = loader.parse(json.object);
		}
	}
}