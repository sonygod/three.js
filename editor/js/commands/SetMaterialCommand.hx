package three.js.editor.js.commands;

import three.js.Command;
import three.ObjectLoader;

class SetMaterialCommand extends Command {
    public var object:three.Object3D;
    public var materialSlot:Int;
    public var oldMaterial:three.Material;
    public var newMaterial:three.Material;

    public function new(editor:Editor, object:three.Object3D = null, newMaterial:three.Material = null, materialSlot:Int = -1) {
        super(editor);

        this.type = 'SetMaterialCommand';
        this.name = editor.strings.getKey('command/SetMaterial');

        this.object = object;
        this.materialSlot = materialSlot;

        this.oldMaterial = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;
        this.newMaterial = newMaterial;
    }

    public function execute():Void {
        editor.setObjectMaterial(object, materialSlot, newMaterial);

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function undo():Void {
        editor.setObjectMaterial(object, materialSlot, oldMaterial);

        editor.signals.materialChanged.dispatch(object, materialSlot);
    }

    public function toJSON():Dynamic {
        var output = super.toJSON(this);

        output.objectUuid = object.uuid;
        output.oldMaterial = oldMaterial.toJSON();
        output.newMaterial = newMaterial.toJSON();
        output.materialSlot = materialSlot;

        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);

        object = editor.objectByUuid(json.objectUuid);
        oldMaterial = parseMaterial(json.oldMaterial);
        newMaterial = parseMaterial(json.newMaterial);
        materialSlot = json.materialSlot;
    }

    private function parseMaterial(json:Dynamic):three.Material {
        var loader = new ObjectLoader();
        var images = loader.parseImages(json.images);
        var textures = loader.parseTextures(json.textures, images);
        var materials = loader.parseMaterials([json], textures);
        return materials[json.uuid];
    }
}