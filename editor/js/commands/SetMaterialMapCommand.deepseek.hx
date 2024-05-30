import three.js.editor.js.commands.Command;
import three.js.ObjectLoader;

class SetMaterialMapCommand extends Command {

	public function new(editor:Editor, object:three.js.Object3D = null, mapName:String = '', newMap:three.js.Texture = null, materialSlot:Int = -1) {
		super(editor);

		this.type = 'SetMaterialMapCommand';
		this.name = editor.strings.getKey('command/SetMaterialMap') + ': ' + mapName;

		this.object = object;
		this.materialSlot = materialSlot;

		var material = (object !== null) ? editor.getObjectMaterial(object, materialSlot) : null;

		this.oldMap = (object !== null) ? material[mapName] : undefined;
		this.newMap = newMap;

		this.mapName = mapName;
	}

	public function execute() {
		if (this.oldMap !== null && this.oldMap !== undefined) this.oldMap.dispose();

		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

		material[this.mapName] = this.newMap;
		material.needsUpdate = true;

		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function undo() {
		var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

		material[this.mapName] = this.oldMap;
		material.needsUpdate = true;

		this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
	}

	public function toJSON() {
		var output = super.toJSON(this);

		output.objectUuid = this.object.uuid;
		output.mapName = this.mapName;
		output.newMap = serializeMap(this.newMap);
		output.oldMap = serializeMap(this.oldMap);
		output.materialSlot = this.materialSlot;

		return output;
	}

	public function fromJSON(json:Dynamic) {
		super.fromJSON(json);

		this.object = this.editor.objectByUuid(json.objectUuid);
		this.mapName = json.mapName;
		this.oldMap = parseTexture(json.oldMap);
		this.newMap = parseTexture(json.newMap);
		this.materialSlot = json.materialSlot;
	}

	private function serializeMap(map:three.js.Texture) {
		if (map === null || map === undefined) return null;

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

	private function extractFromCache(cache:Dynamic) {
		var values = [];
		for (key in cache) {
			var data = cache[key];
			delete data.metadata;
			values.push(data);
		}

		return values;
	}

	private function parseTexture(json:Dynamic) {
		var map:three.js.Texture = null;
		if (json !== null) {
			var loader = new ObjectLoader();
			var images = loader.parseImages(json.images);
			var textures = loader.parseTextures([json], images);
			map = textures[json.uuid];
			map.sourceFile = json.sourceFile;
		}

		return map;
	}
}