package three.js.editor.js.commands;

import js.html.Json;
import js.three.Material;
import js.three.Object3D;
import js.three.ObjectLoader;

class SetMaterialCommand extends Command {
    
    public var type(default, null):String = 'SetMaterialCommand';
    public var name(default, null):String = editor.strings.getKey('command/SetMaterial');
    
    private var object:Object3D;
    private var materialSlot:Int;
    private var oldMaterial:Material;
    private var newMaterial:Material;

    public function new(editor:Editor, object:Object3D = null, newMaterial:Material = null, materialSlot:Int = -1) {
        super(editor);

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
        var output:Dynamic = super.toJSON(this);

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

    private function parseMaterial(json:Dynamic):Material {
        var loader:ObjectLoader = new ObjectLoader();
        var images = loader.parseImages(json.images);
        var textures = loader.parseTextures(json.textures, images);
        var materials:Array<Material> = loader.parseMaterials([json], textures);
        return materials[json.uuid];
    }
}