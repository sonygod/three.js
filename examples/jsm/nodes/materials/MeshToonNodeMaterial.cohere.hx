import NodeMaterial from './NodeMaterial.hx';
import ToonLightingModel from '../functions/ToonLightingModel.hx';

class MeshToonNodeMaterial extends NodeMaterial {
    public var lights:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        this.isMeshToonNodeMaterial = true;
        this.setDefaultValues(defaultValues);
        if (parameters != null) this.setValues(parameters);
    }

    public function setupLightingModel():ToonLightingModel {
        return new ToonLightingModel();
    }
}

var defaultValues:MeshToonMaterial = new MeshToonMaterial();

static function addNodeMaterial(name:String, material:NodeMaterial) {
    // ... add the material to the registry
}

addNodeMaterial('MeshToonNodeMaterial', MeshToonNodeMaterial);

class MeshToonMaterial {
    // ... default values for the material
}