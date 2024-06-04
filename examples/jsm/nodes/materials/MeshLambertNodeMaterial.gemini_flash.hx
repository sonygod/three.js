import NodeMaterial from "./NodeMaterial";
import PhongLightingModel from "../functions/PhongLightingModel";
import three.materials.MeshLambertMaterial;

class MeshLambertNodeMaterial extends NodeMaterial {

    public var isMeshLambertNodeMaterial:Bool = true;
    public var lights:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        this.setDefaultValues(new MeshLambertMaterial());
        if (parameters != null) this.setValues(parameters);
    }

    public function setupLightingModel(builder:Dynamic):PhongLightingModel {
        return new PhongLightingModel(false);
    }

}

class NodeMaterialRegistry {
    public static function addNodeMaterial(name:String, material:NodeMaterial) {
        // Implement your registry logic here.
        // For example, store the material in a map:
        // materials[name] = material;
    }
}

NodeMaterialRegistry.addNodeMaterial("MeshLambertNodeMaterial", new MeshLambertNodeMaterial());