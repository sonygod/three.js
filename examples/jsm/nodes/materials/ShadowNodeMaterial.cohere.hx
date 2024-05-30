import NodeMaterial from './NodeMaterial.hx';
import ShadowMaskModel from '../functions/ShadowMaskModel.hx';

import ShadowMaterial from three/materials/ShadowMaterial.hx;

class ShadowNodeMaterial extends NodeMaterial {

	public var isShadowNodeMaterial:Bool = true;

	public function new(parameters:Dynamic) {
		super();
		this.lights = true;
		this.setDefaultValues(defaultValues);
		this.setValues(parameters);
	}

	public function setupLightingModel():ShadowMaskModel {
		return new ShadowMaskModel();
	}

}

var defaultValues:ShadowMaterial = new ShadowMaterial();

static function __init__() {
	NodeMaterial.addNodeMaterial('ShadowNodeMaterial', ShadowNodeMaterial);
}