import three.core.Object3D;
import three.textures.Texture;
import three.loaders.ObjectLoader;
import js.three.Command;
import js.three.Editor;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param mapName string
 * @param newMap THREE.Texture
 * @constructor
 */
class SetMaterialMapCommand extends Command {

	public var object : Object3D;
	public var mapName : String;
	public var oldMap : Texture;
	public var newMap : Texture;
	public var materialSlot : Int;

	public function new(editor : Editor, object : Object3D = null, mapName : String = "", newMap : Texture = null, materialSlot : Int = -1) {

		super(editor);

		this.type = 'SetMaterialMapCommand';
		this.name = editor.strings.getKey('command/SetMaterialMap') + ': ' + mapName;

		this.object = object;
		this.materialSlot = materialSlot;

		var material : Dynamic = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

		this.oldMap = (object != null) ? material[mapName] : null;
		this.newMap = newMap;

		this.mapName = mapName;

	}

	override public function execute() {

		if (this.oldMap != null) this.oldMap.dispose();

		var material : Dynamic = this.editor.getObjectMaterial(this.object, this.materialSlot);

		material[this.mapName] = this.newMap;
		material.needsUpdate = true;

		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);

	}

	override public function undo() {

		var material : Dynamic = this.editor.getObjectMaterial(this.object, this.materialSlot);

		material[this.mapName] = this.oldMap;
		material.needsUpdate = true;

		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);

	}

	override public function toJSON() : Dynamic {

		var output : Dynamic = super.toJSON();

		output.objectUuid = this.object.uuid;
		output.mapName = this.mapName;
		output.newMap = serializeMap(this.newMap);
		output.oldMap = serializeMap(this.oldMap);
		output.materialSlot = this.materialSlot;

		return output;

	}

	override public function fromJSON(json : Dynamic) {

		super.fromJSON(json);

		this.object = this.editor.objectByUuid(json.objectUuid);
		this.mapName = json.mapName;
		this.oldMap = parseTexture(json.oldMap);
		this.newMap = parseTexture(json.newMap);
		this.materialSlot = json.materialSlot;

	}

	static function serializeMap(map : Texture) : Dynamic {

		if (map == null) return null;

		var meta = {
			geometries: {},
			materials: {},
			textures: {},
			images: {}
		};

		var json = map.toJSON(meta);
		var images = extractFromCache(meta.images);
		if (images.length > 0) json.images = images;
		json.sourceFile = map.sourceFile;

		return json;

	}

	// Note: The function 'extractFromCache' is copied from Object3D.toJSON()

	// extract data from the cache hash
	// remove metadata on each item
	// and return as array
	static function extractFromCache(cache : Dynamic) : Array<Dynamic> {

		var values = [];
		for (key in Reflect.fields(cache)) {

			var data = Reflect.field(cache, key);
			Reflect.deleteField(data, "metadata");
			values.push(data);

		}

		return values;

	}
	
	static function parseTexture(json : Dynamic) : Texture {

		var map : Texture = null;
		if (json != null) {

			var loader = new ObjectLoader();
			var images = loader.parseImages(json.images);
			var textures : Array<Texture> = loader.parseTextures([json], images);
			map = textures[json.uuid];
			map.sourceFile = json.sourceFile;

		}

		return map;

	}

}