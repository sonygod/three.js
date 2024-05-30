import three.NodeMaterial;
import three.ShadowMaskModel;
import three.ShadowMaterial;

class ShadowNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {

        super();

        this.isShadowNodeMaterial = true;

        this.lights = true;

        this.setDefaultValues(new ShadowMaterial());

        this.setValues(parameters);

    }

    public function setupLightingModel(/*builder*/):ShadowMaskModel {

        return new ShadowMaskModel();

    }

}

ShadowNodeMaterial.addNodeMaterial('ShadowNodeMaterial', ShadowNodeMaterial);