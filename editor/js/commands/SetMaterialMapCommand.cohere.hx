import js.Browser.Location;
import js.Browser.Window;
import js.three.Object3D;
import js.three.Texture;
import js.three.Material;

class SetMaterialMapCommand {
    public var type: String;
    public var name: String;
    public var object: Object3D;
    public var materialSlot: Int;
    public var oldMap: Texture;
    public var newMap: Texture;
    public var mapName: String;
    public var editor: Dynamic;

    public function new(editor: Dynamic, ?object: Object3D, mapName: String, ?newMap: Texture, materialSlot: Int = -1) {
        $editor = editor;
        $object = object;
        $mapName = mapName;
        $newMap = newMap;
        $materialSlot = materialSlot;

        $type = 'SetMaterialMapCommand';
        $name = editor.strings.getKey('command/SetMaterialMap') + ': ' + mapName;

        var material: Material = if (object != null) editor.getObjectMaterial(object, materialSlot) else null;
        $oldMap = if (object != null) material[$mapName] else null;
    }

    public function execute(): Void {
        if ($oldMap != null) {
            $oldMap.dispose();
        }

        var material: Material = editor.getObjectMaterial(object, materialSlot);
        material[mapName] = newMap;
        material.needsUpdate = true;

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo(): Void {
        var material: Material = editor.getObjectMaterial(object, materialSlot);
        material[mapName] = oldMap;
        material.needsUpdate = true;

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function toJSON(): Dynamic {
        var output: Dynamic = {
            objectUuid: object.uuid,
            mapName: mapName,
            newMap: serializeMap(newMap),
            oldMap: serializeMap(oldMap),
            materialSlot: materialSlot
        };

        return output;
    }

    private function serializeMap(map: Texture): Dynamic {
        if (map == null) {
            return null;
        }

        var meta: Dynamic = {
            geometries: {},
            materials: {},
            textures: {},
            images: {}
        };

        var json: Dynamic = map.toJSON(meta);
        var images: Array<Dynamic> = extractFromCache(meta.images);
        if (images.length > 0) {
            json.images = images;
        }
        json.sourceFile = map.sourceFile;

        return json;
    }

    private function extractFromCache(cache: Dynamic): Array<Dynamic> {
        var values: Array<Dynamic> = [];
        for (key in cache) {
            var data: Dynamic = cache[key];
            delete data.metadata;
            values.push(data);
        }

        return values;
    }

    public function fromJSON(json: Dynamic): Void {
        object = editor.objectByUuid(json.objectUuid);
        mapName = json.mapName;
        oldMap = parseTexture(json.oldMap);
        newMap = parseTexture(json.newMap);
        materialSlot = json.materialSlot;
    }

    private function parseTexture(json: Dynamic): Texture {
        var map: Texture = null;
        if (json != null) {
            var loader: ObjectLoader = new ObjectLoader();
            var images: Array<Dynamic> = loader.parseImages(json.images);
            var textures: Array<Dynamic> = loader.parseTextures([json], images);
            map = textures[json.uuid];
            map.sourceFile = json.sourceFile;
        }

        return map;
    }
}

class ObjectLoader {
    public function parseImages(images: Array<Dynamic>): Array<Dynamic> {
        // Implementation needed
    }

    public function parseTextures(textures: Array<Dynamic>, images: Array<Dynamic>): Array<Dynamic> {
        // Implementation needed
    }
}