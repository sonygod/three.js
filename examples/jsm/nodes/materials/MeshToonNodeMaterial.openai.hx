package three.js.examples.jsm.nodes.materials;

import three.js.NodeMaterial;
import three.js.functions.ToonLightingModel;

class MeshToonNodeMaterial extends NodeMaterial {
    public var isMeshToonNodeMaterial:Bool = true;
    public var lights:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        setDefaultValues(new three.js.MeshToonMaterial());
        if (parameters != null) setValues(parameters);
    }

    override public function setupLightingModel(builder:Dynamic):ToonLightingModel {
        return new ToonLightingModel();
    }
}

typedef MeshToonNodeMaterialDef = { };

typedef MeshToonNodeMaterialParams = { ?lights:Bool, ?parameters:MeshToonNodeMaterialDef };

@:keep
@:forward
abstract MeshToonNodeMaterial(MeshToonNodeMaterial) from MeshToonNodeMaterial to MeshToonNodeMaterial {
    inline function new(?parameters:MeshToonNodeMaterialParams) {
        this = new MeshToonNodeMaterial(parameters);
    }
}

// Register the material
NodeMaterial.addNodeMaterial('MeshToonNodeMaterial', MeshToonNodeMaterial);