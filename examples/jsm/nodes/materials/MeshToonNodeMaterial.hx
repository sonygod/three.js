package three.js.examples.jsm.nodes.materials;

import NodeMaterial;
import ToonLightingModel;

class MeshToonNodeMaterial extends NodeMaterial {

    public var isMeshToonNodeMaterial:Bool = true;
    public var lights:Bool = true;

    public function new(parameters:Dynamic) {
        super();
        setDefaultValues(new MeshToonMaterial());
        setValues(parameters);
    }

    public function setupLightingModel(builder:Dynamic):ToonLightingModel {
        return new ToonLightingModel();
    }

}

registerNodeMaterial("MeshToonNodeMaterial", MeshToonNodeMaterial);