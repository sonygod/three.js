import js.three.Command;
import js.three.ObjectLoader;

class SetMaterialMapCommand extends Command {
    public var object: THREE.Object3D;
    public var materialSlot: Int;
    public var oldMap: THREE.Texture;
    public var newMap: THREE.Texture;
    public var mapName: String;

    public function new(editor: Editor, ?object: THREE.Object3D, ?mapName: String, ?newMap: THREE.Texture, ?materialSlot: Int) {
        super(editor);

        this.type = 'SetMaterialMapCommand';
        this.name = editor.strings.getKey('command/SetMaterialMap') + ': ' + (mapName == null ? '' : mapName);

        this.object = object == null ? null : object;
        this.materialSlot = materialSlot == null ? -1 : materialSlot;

        var material = (this.object != null) ? editor.getObjectMaterial(this.object, this.materialSlot) : null;

        this.oldMap = (this.object != null) ? Reflect.field(material, mapName) : null;
        this.newMap = newMap == null ? null : newMap;

        this.mapName = mapName == null ? '' : mapName;
    }

    public function execute(): Void {
        if (this.oldMap != null) this.oldMap.dispose();

        var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        Reflect.setField(material, this.mapName, this.newMap);
        material.needsUpdate = true;

        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    public function undo(): Void {
        var material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        Reflect.setField(material, this.mapName, this.oldMap);
        material.needsUpdate = true;

        this.editor.signals.materialChanged.dispatch(this.object, this.materialSlot);
    }

    public function toJSON(): Dynamic {
        var output = super.toJSON();

        output.objectUuid = this.object.uuid;
        output.mapName = this.mapName;
        output.newMap = serializeMap(this.newMap);
        output.oldMap = serializeMap(this.oldMap);
        output.materialSlot = this.materialSlot;

        return output;
    }

    private function serializeMap(map: THREE.Texture): Dynamic {
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

    private function extractFromCache(cache: Dynamic): Array<Dynamic> {
        var values = [];
        for (key in Reflect.fields(cache)) {
            var data = Reflect.field(cache, key);
            Reflect.deleteField(data, 'metadata');
            values.push(data);
        }

        return values;
    }

    public function fromJSON(json: Dynamic): Void {
        super.fromJSON(json);

        this.object = this.editor.objectByUuid(json.objectUuid);
        this.mapName = json.mapName;
        this.oldMap = parseTexture(json.oldMap);
        this.newMap = parseTexture(json.newMap);
        this.materialSlot = json.materialSlot;
    }

    private function parseTexture(json: Dynamic): THREE.Texture {
        if (json == null) return null;

        var loader = new ObjectLoader();
        var images = loader.parseImages(json.images);
        var textures = loader.parseTextures([json], images);
        var map = textures[json.uuid];
        map.sourceFile = json.sourceFile;

        return map;
    }
}