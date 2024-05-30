package three.js.examples.jsm.nodes.materials;

import three.js.nodes.NodeMaterial;
import three.js.functions.ShadowMaskModel;

class ShadowNodeMaterial extends NodeMaterial {
    public var isShadowNodeMaterial:Bool = true;
    public var lights:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        setDefaultValues(new three.js Materials.ShadowMaterial());
        setValues(parameters);
    }

    public function setupLightingModel(builder:Dynamic):ShadowMaskModel {
        return new ShadowMaskModel();
    }
}

.addNodeMaterial('ShadowNodeMaterial', ShadowNodeMaterial);