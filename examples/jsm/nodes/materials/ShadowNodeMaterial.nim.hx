import NodeMaterial.NodeMaterial;
import NodeMaterial.addNodeMaterial;
import ShadowMaskModel.ShadowMaskModel;

import three.ShadowMaterial;

class ShadowNodeMaterial extends NodeMaterial {

    public var isShadowNodeMaterial:Bool = true;
    public var lights:Bool = true;

    public function new(parameters:Dynamic) {

        super();

        this.isShadowNodeMaterial = true;

        this.lights = true;

        this.setDefaultValues(new ShadowMaterial());

        this.setValues(parameters);

    }

    public function setupLightingModel(builder:Dynamic) {

        return new ShadowMaskModel();

    }

}

addNodeMaterial('ShadowNodeMaterial', ShadowNodeMaterial);