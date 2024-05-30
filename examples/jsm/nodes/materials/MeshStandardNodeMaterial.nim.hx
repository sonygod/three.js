import NodeMaterial, { addNodeMaterial } from './NodeMaterial.js';
import { diffuseColor, metalness, roughness, specularColor, specularF90 } from '../core/PropertyNode.js';
import { mix } from '../math/MathNode.js';
import { materialRoughness, materialMetalness } from '../accessors/MaterialNode.js';
import getRoughness from '../functions/material/getRoughness.js';
import PhysicalLightingModel from '../functions/PhysicalLightingModel.js';
import { float, vec3, vec4 } from '../shadernode/ShaderNode.js';

import { MeshStandardMaterial } from 'three';

class MeshStandardNodeMaterial extends NodeMaterial {

	public var isMeshStandardNodeMaterial:Bool = true;
	public var emissiveNode:Null<Dynamic> = null;
	public var metalnessNode:Null<Dynamic> = null;
	public var roughnessNode:Null<Dynamic> = null;

	public function new( parameters:Dynamic ) {
		super();

		this.setDefaultValues( new MeshStandardMaterial() );
		this.setValues( parameters );
	}

	public function setupLightingModel( /*builder*/ ) {
		return new PhysicalLightingModel();
	}

	public function setupSpecular() {
		const specularColorNode = mix( vec3( 0.04 ), diffuseColor.rgb, metalness );

		specularColor.assign( specularColorNode );
		specularF90.assign( 1.0 );
	}

	public function setupVariants() {
		// METALNESS
		const metalnessNode = this.metalnessNode != null ? float( this.metalnessNode ) : materialMetalness;

		metalness.assign( metalnessNode );

		// ROUGHNESS
		let roughnessNode = this.roughnessNode != null ? float( this.roughnessNode ) : materialRoughness;
		roughnessNode = getRoughness( { roughness: roughnessNode } );

		roughness.assign( roughnessNode );

		// SPECULAR COLOR
		this.setupSpecular();

		// DIFFUSE COLOR
		diffuseColor.assign( vec4( diffuseColor.rgb.mul( metalnessNode.oneMinus() ), diffuseColor.a ) );
	}

	public function copy( source:MeshStandardNodeMaterial ) {
		this.emissiveNode = source.emissiveNode;
		this.metalnessNode = source.metalnessNode;
		this.roughnessNode = source.roughnessNode;

		return super.copy( source );
	}
}

addNodeMaterial( 'MeshStandardNodeMaterial', MeshStandardNodeMaterial );