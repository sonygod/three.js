import three.core.Object3D;
import three.loaders.ObjectLoader;

class RemoveObjectCommand extends Command {

	public var object:Object3D;
	public var parent:Object3D;
	public var index:Int;

	public function new(editor:Editor, object:Object3D = null) {

		super(editor);

		this.type = 'RemoveObjectCommand';

		this.object = object;
		this.parent = (object != null) ? object.parent : null;

		if (this.parent != null) {
			this.index = this.parent.children.indexOf(this.object);
		}

		if (object != null) {
			this.name = editor.strings.getKey('command/RemoveObject') + ': ' + object.name;
		}
	}

	override public function execute():Void {
		this.editor.removeObject(this.object);
		this.editor.deselect();
	}

	override public function undo():Void {
		this.editor.addObject(this.object, this.parent, this.index);
		this.editor.select(this.object);
	}

	override public function toJSON():Dynamic {
		var output = super.toJSON();

		output.object = this.object.toJSON();
		output.index = this.index;
		output.parentUuid = this.parent.uuid;

		return output;
	}

	override public function fromJSON(json:Dynamic):Void {
		super.fromJSON(json);

		this.parent = this.editor.objectByUuid(json.parentUuid);
		if (this.parent == null) {
			this.parent = this.editor.scene;
		}

		this.index = json.index;

		this.object = this.editor.objectByUuid(json.object.object.uuid);

		if (this.object == null) {
			var loader = new ObjectLoader();
			this.object = loader.parse(json.object);
		}
	}
}