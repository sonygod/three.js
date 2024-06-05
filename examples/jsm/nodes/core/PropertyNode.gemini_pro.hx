import Node from "./Node";
import {nodeImmutable, nodeObject} from "../shadernode/ShaderNode";

class PropertyNode extends Node {

	public name: String;
	public varying: Bool;

	public constructor(nodeType: String, name: String = null, varying: Bool = false) {
		super(nodeType);
		this.name = name;
		this.varying = varying;
		this.isPropertyNode = true;
	}

	public getHash(builder: Any): String {
		return this.name != null ? this.name : super.getHash(builder);
	}

	public isGlobal(builder: Any): Bool {
		return true;
	}

	public generate(builder: Any): String {
		var nodeVar: Any;
		if (this.varying) {
			nodeVar = builder.getVaryingFromNode(this, this.name);
			nodeVar.needsInterpolation = true;
		}
		else {
			nodeVar = builder.getVarFromNode(this, this.name);
		}
		return builder.getPropertyName(nodeVar);
	}
}

export default PropertyNode;

export function property(type: String, name: String): Any {
	return nodeObject(new PropertyNode(type, name));
}

export function varyingProperty(type: String, name: String): Any {
	return nodeObject(new PropertyNode(type, name, true));
}

export const diffuseColor = nodeImmutable(PropertyNode, 'vec4', 'DiffuseColor');
export const roughness = nodeImmutable(PropertyNode, 'float', 'Roughness');
export const metalness = nodeImmutable(PropertyNode, 'float', 'Metalness');
export const clearcoat = nodeImmutable(PropertyNode, 'float', 'Clearcoat');
export const clearcoatRoughness = nodeImmutable(PropertyNode, 'float', 'ClearcoatRoughness');
export const sheen = nodeImmutable(PropertyNode, 'vec3', 'Sheen');
export const sheenRoughness = nodeImmutable(PropertyNode, 'float', 'SheenRoughness');
export const iridescence = nodeImmutable(PropertyNode, 'float', 'Iridescence');
export const iridescenceIOR = nodeImmutable(PropertyNode, 'float', 'IridescenceIOR');
export const iridescenceThickness = nodeImmutable(PropertyNode, 'float', 'IridescenceThickness');
export const alphaT = nodeImmutable(PropertyNode, 'float', 'AlphaT');
export const anisotropy = nodeImmutable(PropertyNode, 'float', 'Anisotropy');
export const anisotropyT = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyT');
export const anisotropyB = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyB');
export const specularColor = nodeImmutable(PropertyNode, 'color', 'SpecularColor');
export const specularF90 = nodeImmutable(PropertyNode, 'float', 'SpecularF90');
export const shininess = nodeImmutable(PropertyNode, 'float', 'Shininess');
export const output = nodeImmutable(PropertyNode, 'vec4', 'Output');
export const dashSize = nodeImmutable(PropertyNode, 'float', 'dashSize');
export const gapSize = nodeImmutable(PropertyNode, 'float', 'gapSize');
export const pointWidth = nodeImmutable(PropertyNode, 'float', 'pointWidth');
export const ior = nodeImmutable(PropertyNode, 'float', 'IOR');
export const transmission = nodeImmutable(PropertyNode, 'float', 'Transmission');
export const thickness = nodeImmutable(PropertyNode, 'float', 'Thickness');
export const attenuationDistance = nodeImmutable(PropertyNode, 'float', 'AttenuationDistance');
export const attenuationColor = nodeImmutable(PropertyNode, 'color', 'AttenuationColor');

Node.addNodeClass('PropertyNode', PropertyNode);