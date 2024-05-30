import NodeMaterial.NodeMaterial;
import ToonLightingModel.ToonLightingModel;
import three.MeshToonMaterial;

class MeshToonNodeMaterial extends NodeMaterial {
    public var isMeshToonNodeMaterial:Bool = true;
    public var lights:Bool = true;

    public function new(parameters:Dynamic) {
        super();

        this.setDefaultValues(new MeshToonMaterial());
        this.setValues(parameters);
    }

    public function setupLightingModel(builder:Dynamic):ToonLightingModel {
        return new ToonLightingModel();
    }

    static function main() {
        addNodeMaterial('MeshToonNodeMaterial', MeshToonNodeMaterial);
    }
}