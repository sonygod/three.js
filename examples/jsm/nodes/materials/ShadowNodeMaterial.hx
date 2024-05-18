package three.js.examples.jsm.nodes.materials;

import three.js.examples.jsm.nodes.NodeMaterial;
import three.js.examples.functions.ShadowMaskModel;

import three.ShadowMaterial;

class ShadowNodeMaterial extends NodeMaterial {

    public var isShadowNodeMaterial:Bool = true;

    public var lights:Bool = true;

    public function new(parameters:Dynamic) {
        super();

        setDefaultValues(new ShadowMaterial());

        setValues(parameters);
    }

    public function setupLightingModel(builder:Dynamic):ShadowMaskModel {
        return new ShadowMaskModel();
    }

    static public function main() {
        NodeMaterial.addNodeMaterial('ShadowNodeMaterial', ShadowNodeMaterial);
    }
}