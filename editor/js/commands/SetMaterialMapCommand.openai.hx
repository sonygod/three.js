package three.js.editor.js.commands;

import three.js.editor.Command;
import three.ObjectLoader;

class SetMaterialMapCommand extends Command {
    public var object : three.Object3D;
    public var materialSlot : Int;
    public var oldMap : three.Texture;
    public var newMap : three.Texture;
    public var mapName : String;

    public function new(editor : Editor, object : three.Object3D = null, mapName : String = '', newMap : three.Texture = null, materialSlot : Int = -1) {
        super(editor);
        this.type = 'SetMaterialMapCommand';
        this.name = editor.strings.getKey('command/SetMaterialMap') + ': ' + mapName;
        this.object = object;
        this.materialSlot = materialSlot;
        if (object != null) {
            var material = editor.getObjectMaterial(object, materialSlot);
            oldMap = material[mapName];
        } else {
            oldMap = null;
        }
        this.newMap = newMap;
        this.mapName = mapName;
    }

    public function execute() : Void {
        if (oldMap != null) oldMap.dispose();
        var material = editor.getObjectMaterial(object, materialSlot);
        material[mapName] = newMap;
        material.needsUpdate = true;
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo() : Void {
        var material = editor.getObjectMaterial(object, materialSlot);
        material[mapName] = oldMap;
        material.needsUpdate = true;
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function toJSON() : Dynamic {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.mapName = mapName;
        output.newMap = serializeMap(newMap);
        output.oldMap = serializeMap(oldMap);
        output.materialSlot = materialSlot;
        return output;
    }

    private function serializeMap(map : three.Texture) : Dynamic {
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

    private function extractFromCache(cache : Dynamic) : Array<Dynamic> {
        var values = [];
        for (key in cache.keys()) {
            var data = cache[key];
            delete data.metadata;
            values.push(data);
        }
        return values;
    }

    public function fromJSON(json : Dynamic) : Void {
        super.fromJSON(json);
        object = editor.objectByUuid(json.objectUuid);
        mapName = json.mapName;
        oldMap = parseTexture(json.oldMap);
        newMap = parseTexture(json.newMap);
        materialSlot = json.materialSlot;
    }

    private function parseTexture(json : Dynamic) : three.Texture {
        var map : three.Texture = null;
        if (json != null) {
            var loader = new ObjectLoader();
            var images = loader.parseImages(json.images);
            var textures = loader.parseTextures([json], images);
            map = textures[json.uuid];
            map.sourceFile = json.sourceFile;
        }
        return map;
    }
}