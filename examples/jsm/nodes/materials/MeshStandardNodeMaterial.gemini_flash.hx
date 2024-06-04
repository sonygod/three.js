import NodeMaterial from "./NodeMaterial";
import { addNodeMaterial } from "./NodeMaterial";
import { diffuseColor, metalness, roughness, specularColor, specularF90 } from "../core/PropertyNode";
import { mix } from "../math/MathNode";
import { materialRoughness, materialMetalness } from "../accessors/MaterialNode";
import getRoughness from "../functions/material/getRoughness";
import PhysicalLightingModel from "../functions/PhysicalLightingModel";
import { float, vec3, vec4 } from "../shadernode/ShaderNode";
import { MeshStandardMaterial } from "three";

class MeshStandardNodeMaterial extends NodeMaterial {

	public emissiveNode:Dynamic = null;
	public metalnessNode:Dynamic = null;
	public roughnessNode:Dynamic = null;

	public constructor( parameters:Dynamic = null ) {
		super();

		this.isMeshStandardNodeMaterial = true;

		this.setDefaultValues( new MeshStandardMaterial() );

		if (parameters != null) {
			this.setValues(parameters);
		}
	}

	public setupLightingModel( /*builder*/ ) {
		return new PhysicalLightingModel();
	}

	public setupSpecular() {
		specularColor.assign( mix(vec3(0.04), diffuseColor.rgb, metalness) );
		specularF90.assign(1.0);
	}

	public setupVariants() {
		// METALNESS
		metalness.assign( this.metalnessNode != null ? float(this.metalnessNode) : materialMetalness );

		// ROUGHNESS
		var roughnessNode = this.roughnessNode != null ? float(this.roughnessNode) : materialRoughness;
		roughnessNode = getRoughness({roughness:roughnessNode});
		roughness.assign(roughnessNode);

		// SPECULAR COLOR
		this.setupSpecular();

		// DIFFUSE COLOR
		diffuseColor.assign( vec4(diffuseColor.rgb.mul(metalness.oneMinus()), diffuseColor.a) );
	}

	public copy( source:MeshStandardNodeMaterial ) {
		this.emissiveNode = source.emissiveNode;
		this.metalnessNode = source.metalnessNode;
		this.roughnessNode = source.roughnessNode;

		return super.copy(source);
	}
}

export default MeshStandardNodeMaterial;
addNodeMaterial("MeshStandardNodeMaterial", MeshStandardNodeMaterial);