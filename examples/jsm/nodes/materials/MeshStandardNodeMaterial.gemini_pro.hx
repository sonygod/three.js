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

	public emissiveNode: Dynamic<Float> = null;

	public metalnessNode: Dynamic<Float> = null;
	public roughnessNode: Dynamic<Float> = null;

	public constructor(parameters: Dynamic<Dynamic>) {
		super();
		this.isMeshStandardNodeMaterial = true;
		this.setDefaultValues(new MeshStandardMaterial());
		this.setValues(parameters);
	}

	public setupLightingModel(): PhysicalLightingModel {
		return new PhysicalLightingModel();
	}

	public setupSpecular(): Void {
		specularColor.assign(mix(vec3(0.04), diffuseColor.rgb, metalness));
		specularF90.assign(1.0);
	}

	public setupVariants(): Void {
		// METALNESS
		metalness.assign(this.metalnessNode != null ? float(this.metalnessNode) : materialMetalness);

		// ROUGHNESS
		var roughnessNode = this.roughnessNode != null ? float(this.roughnessNode) : materialRoughness;
		roughnessNode = getRoughness({roughness: roughnessNode});
		roughness.assign(roughnessNode);

		// SPECULAR COLOR
		this.setupSpecular();

		// DIFFUSE COLOR
		diffuseColor.assign(vec4(diffuseColor.rgb.mul(metalnessNode.oneMinus()), diffuseColor.a));
	}

	public copy(source: MeshStandardNodeMaterial): MeshStandardNodeMaterial {
		this.emissiveNode = source.emissiveNode;
		this.metalnessNode = source.metalnessNode;
		this.roughnessNode = source.roughnessNode;
		return super.copy(source);
	}
}

addNodeMaterial("MeshStandardNodeMaterial", MeshStandardNodeMaterial);