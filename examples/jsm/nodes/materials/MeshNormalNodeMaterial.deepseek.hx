import NodeMaterial, { addNodeMaterial } from './NodeMaterial.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { directionToColor } from '../utils/PackingNode.js';
import { materialOpacity } from '../accessors/MaterialNode.js';
import { transformedNormalView } from '../accessors/NormalNode.js';
import { float, vec4 } from '../shadernode/ShaderNode.js';

import { MeshNormalMaterial } from 'three';

var defaultValues = new MeshNormalMaterial();

class MeshNormalNodeMaterial extends NodeMaterial {

	public function new(parameters) {

		super();

		this.isMeshNormalNodeMaterial = true;

		this.setDefaultValues(defaultValues);

		this.setValues(parameters);

	}

	public function setupDiffuseColor() {

		var opacityNode = this.opacityNode ? float(this.opacityNode) : materialOpacity;

		diffuseColor.assign(vec4(directionToColor(transformedNormalView), opacityNode));

	}

}

export default MeshNormalNodeMaterial;

addNodeMaterial('MeshNormalNodeMaterial', MeshNormalNodeMaterial);