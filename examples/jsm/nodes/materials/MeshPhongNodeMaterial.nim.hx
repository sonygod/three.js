import NodeMaterial, { addNodeMaterial } from './NodeMaterial.js';
import { shininess, specularColor } from '../core/PropertyNode.js';
import { materialShininess, materialSpecular } from '../accessors/MaterialNode.js';
import { float } from '../shadernode/ShaderNode.js';
import PhongLightingModel from '../functions/PhongLightingModel.js';

import MeshPhongMaterial from 'three';

class DefaultValues extends MeshPhongMaterial {}

class MeshPhongNodeMaterial extends NodeMaterial {

	public var isMeshPhongNodeMaterial:Bool = true;
	public var lights:Bool = true;
	public var shininessNode:Dynamic;
	public var specularNode:Dynamic;

	public function new( parameters:Dynamic ) {

		super();

		this.setDefaultValues( new DefaultValues() );

		this.setValues( parameters );

	}

	public function setupLightingModel( /*builder*/ ) {

		return new PhongLightingModel();

	}

	public function setupVariants() {

		// SHININESS

		var shininessNode = ( this.shininessNode ? float( this.shininessNode ) : materialShininess ).max( 1e-4 ); // to prevent pow( 0.0, 0.0 )

		shininess.assign( shininessNode );

		// SPECULAR COLOR

		var specularNode = this.specularNode || materialSpecular;

		specularColor.assign( specularNode );

	}

	public function copy( source:MeshPhongNodeMaterial ) {

		this.shininessNode = source.shininessNode;
		this.specularNode = source.specularNode;

		return super.copy( source );

	}

}

export default MeshPhongNodeMaterial;

addNodeMaterial( 'MeshPhongNodeMaterial', MeshPhongNodeMaterial );