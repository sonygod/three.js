import js.Browser.Commands.Command;

class SetMaterialCommand extends Command {
    public var object:Dynamic;
    public var materialSlot:Int;
    public var oldMaterial:Dynamic;
    public var newMaterial:Dynamic;

    public function new(editor:Dynamic, ?object:Dynamic, ?newMaterial:Dynamic, materialSlot:Int = -1) {
        super(editor);
        $type = 'SetMaterialCommand';
        $name = editor.strings.getKey('command/SetMaterial');
        $object = object;
        $materialSlot = materialSlot;
        $oldMaterial = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;
        $newMaterial = newMaterial;
    }

    public function execute() {
        editor.setObjectMaterial(object, materialSlot, newMaterial);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo() {
        editor.setObjectMaterial(object, materialSlot, oldMaterial);
        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.objectUuid = object.uuid;
        output.oldMaterial = oldMaterial.toJSON();
        output.newMaterial = newMaterial.toJSON();
        output.materialSlot = materialSlot;
        return output;
    }

    public function fromJSON(json:Dynamic) {
        super.fromJSON(json);
        object = editor.objectByUuid(json.objectUuid);
        oldMaterial = parseMaterial(json.oldMaterial);
        newMaterial = parseMaterial(json.newMaterial);
        materialSlot = json.materialSlot;
    }

    private function parseMaterial(json:Dynamic):Dynamic {
        var loader = new js.three.ObjectLoader();
        var images = loader.parseImages(json.images);
        var textures = loader.parseTextures(json.textures, images);
        var materials = loader.parseMaterials([json], textures);
        return materials[json.uuid];
    }
}

class js {
    class Browser {
        class Commands {
            class Command { }
        }
    }

    class three {
        class ObjectLoader { }
    }
}