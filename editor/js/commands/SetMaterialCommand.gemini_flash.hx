import three.Object3D;
import three.Material;
import three.loaders.ObjectLoader;

class SetMaterialCommand extends Command {

	public var object:Object3D;
	public var materialSlot:Int;
	public var oldMaterial:Material;
	public var newMaterial:Material;

	public function new(editor:Editor, object:Object3D = null, newMaterial:Material = null, materialSlot:Int = -1) {

		super(editor);

		this.type = 'SetMaterialCommand';
		this.name = editor.strings.getKey('command/SetMaterial');

		this.object = object;
		this.materialSlot = materialSlot;

		this.oldMaterial = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;
		this.newMaterial = newMaterial;

	}

	override public function execute():Void {

		this.editor.setObjectMaterial(this.object, this.materialSlot, this.newMaterial);

		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);

	}

	override public function undo():Void {

		this.editor.setObjectMaterial(this.object, this.materialSlot, this.oldMaterial);

		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);

	}

	override public function toJSON():Dynamic {

		var output = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.oldMaterial = this.oldMaterial.toJSON();
		output.newMaterial = this.newMaterial.toJSON();
		output.materialSlot = this.materialSlot;

		return output;

	}

	override public function fromJSON(json:Dynamic):Void {

		super.fromJSON(json);

		this.object = this.editor.objectByUuid(json.objectUuid);
		this.oldMaterial = parseMaterial(json.oldMaterial);
		this.newMaterial = parseMaterial(json.newMaterial);
		this.materialSlot = json.materialSlot;

		function parseMaterial(json:Dynamic):Material {

			var loader = new ObjectLoader();
			var images = loader.parseImages(json.images);
			var textures = loader.parseTextures(json.textures, images);
			var materials = loader.parseMaterials([json], textures);
			return materials[json.uuid];

		}

	}

}