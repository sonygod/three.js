import NodeMaterial;
import NodeMaterial.addNodeMaterial;
import ShadowMaskModel;
import three.ShadowMaterial;

class ShadowNodeMaterial extends NodeMaterial {

    static var defaultValues:ShadowMaterial = new ShadowMaterial();

    public function new(parameters:Dynamic) {
        super();
        this.isShadowNodeMaterial = true;
        this.lights = true;
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public function setupLightingModel():ShadowMaskModel {
        return new ShadowMaskModel();
    }

}

addNodeMaterial('ShadowNodeMaterial', ShadowNodeMaterial);