import NodeMaterial, { addNodeMaterial } from './NodeMaterial.js';
import { shininess, specularColor } from '../core/PropertyNode.js';
import { materialShininess, materialSpecular } from '../accessors/MaterialNode.js';
import { float } from '../shadernode/ShaderNode.js';
import PhongLightingModel from '../functions/PhongLightingModel.js';

import { MeshPhongMaterial } from 'three';

class MeshPhongNodeMaterial extends NodeMaterial {

	public var isMeshPhongNodeMaterial:Bool = true;
	public var lights:Bool = true;
	public var shininessNode:Dynamic = null;
	public var specularNode:Dynamic = null;

	public function new(parameters:Dynamic) {
		super();

		var defaultValues = new MeshPhongMaterial();
		this.setDefaultValues(defaultValues);

		this.setValues(parameters);
	}

	public function setupLightingModel(/*builder*/):PhongLightingModel {
		return new PhongLightingModel();
	}

	public function setupVariants() {
		// SHININESS
		var shininessNode = (this.shininessNode ? float(this.shininessNode) : materialShininess).max(1e-4); // to prevent pow(0.0, 0.0)
		shininess.assign(shininessNode);

		// SPECULAR COLOR
		var specularNode = this.specularNode || materialSpecular;
		specularColor.assign(specularNode);
	}

	public function copy(source:MeshPhongNodeMaterial):MeshPhongNodeMaterial {
		this.shininessNode = source.shininessNode;
		this.specularNode = source.specularNode;

		return super.copy(source);
	}

}

addNodeMaterial('MeshPhongNodeMaterial', MeshPhongNodeMaterial);