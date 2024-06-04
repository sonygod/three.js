import Node from "./Node";
import ShaderNode from "../shadernode/ShaderNode";

class PropertyNode extends Node {

	public name: String;
	public varying: Bool;

	public constructor(nodeType: String, name: String = null, varying: Bool = false) {
		super(nodeType);
		this.name = name;
		this.varying = varying;
		this.isPropertyNode = true;
	}

	public getHash(builder: Any) {
		return this.name != null ? this.name : super.getHash(builder);
	}

	public isGlobal(builder: Any) {
		return true;
	}

	public generate(builder: Any) {
		var nodeVar: Any;
		if (this.varying) {
			nodeVar = builder.getVaryingFromNode(this, this.name);
			nodeVar.needsInterpolation = true;
		} else {
			nodeVar = builder.getVarFromNode(this, this.name);
		}
		return builder.getPropertyName(nodeVar);
	}

}

export function property(type: String, name: String) {
	return ShaderNode.nodeObject(new PropertyNode(type, name));
}

export function varyingProperty(type: String, name: String) {
	return ShaderNode.nodeObject(new PropertyNode(type, name, true));
}

export var diffuseColor = ShaderNode.nodeImmutable(PropertyNode, 'vec4', 'DiffuseColor');
export var roughness = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Roughness');
export var metalness = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Metalness');
export var clearcoat = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Clearcoat');
export var clearcoatRoughness = ShaderNode.nodeImmutable(PropertyNode, 'float', 'ClearcoatRoughness');
export var sheen = ShaderNode.nodeImmutable(PropertyNode, 'vec3', 'Sheen');
export var sheenRoughness = ShaderNode.nodeImmutable(PropertyNode, 'float', 'SheenRoughness');
export var iridescence = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Iridescence');
export var iridescenceIOR = ShaderNode.nodeImmutable(PropertyNode, 'float', 'IridescenceIOR');
export var iridescenceThickness = ShaderNode.nodeImmutable(PropertyNode, 'float', 'IridescenceThickness');
export var alphaT = ShaderNode.nodeImmutable(PropertyNode, 'float', 'AlphaT');
export var anisotropy = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Anisotropy');
export var anisotropyT = ShaderNode.nodeImmutable(PropertyNode, 'vec3', 'AnisotropyT');
export var anisotropyB = ShaderNode.nodeImmutable(PropertyNode, 'vec3', 'AnisotropyB');
export var specularColor = ShaderNode.nodeImmutable(PropertyNode, 'color', 'SpecularColor');
export var specularF90 = ShaderNode.nodeImmutable(PropertyNode, 'float', 'SpecularF90');
export var shininess = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Shininess');
export var output = ShaderNode.nodeImmutable(PropertyNode, 'vec4', 'Output');
export var dashSize = ShaderNode.nodeImmutable(PropertyNode, 'float', 'dashSize');
export var gapSize = ShaderNode.nodeImmutable(PropertyNode, 'float', 'gapSize');
export var pointWidth = ShaderNode.nodeImmutable(PropertyNode, 'float', 'pointWidth');
export var ior = ShaderNode.nodeImmutable(PropertyNode, 'float', 'IOR');
export var transmission = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Transmission');
export var thickness = ShaderNode.nodeImmutable(PropertyNode, 'float', 'Thickness');
export var attenuationDistance = ShaderNode.nodeImmutable(PropertyNode, 'float', 'AttenuationDistance');
export var attenuationColor = ShaderNode.nodeImmutable(PropertyNode, 'color', 'AttenuationColor');

ShaderNode.addNodeClass('PropertyNode', PropertyNode);