import NodeMaterial;
import ToonLightingModel;
import three.MeshToonMaterial;

class MeshToonNodeMaterial extends NodeMaterial {
    public function new(parameters:Dynamic) {
        super();
        this.isMeshToonNodeMaterial = true;
        this.lights = true;
        this.setDefaultValues(new MeshToonMaterial());
        this.setValues(parameters);
    }

    public function setupLightingModel(/*builder:Dynamic*/):ToonLightingModel {
        return new ToonLightingModel();
    }
}

NodeMaterial.addNodeMaterial('MeshToonNodeMaterial', MeshToonNodeMaterial);