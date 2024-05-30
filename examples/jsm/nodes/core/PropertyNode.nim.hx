import Node, { addNodeClass } from './Node.js';
import { nodeImmutable, nodeObject } from '../shadernode/ShaderNode.js';

class PropertyNode extends Node {

	public var name:String;
	public var varying:Bool;

	public function new(nodeType:String, name:String = null, varying:Bool = false) {

		super(nodeType);

		this.name = name;
		this.varying = varying;

		this.isPropertyNode = true;

	}

	public function getHash(builder:ShaderBuilder):String {

		return this.name || super.getHash(builder);

	}

	public function isGlobal(builder:ShaderBuilder):Bool {

		return true;

	}

	public function generate(builder:ShaderBuilder):String {

		var nodeVar;

		if (this.varying) {

			nodeVar = builder.getVaryingFromNode(this, this.name);
			nodeVar.needsInterpolation = true;

		} else {

			nodeVar = builder.getVarFromNode(this, this.name);

		}

		return builder.getPropertyName(nodeVar);

	}

}

export default PropertyNode;

export function property(type:String, name:String):ShaderNode {
	return nodeObject(new PropertyNode(type, name));
}

export function varyingProperty(type:String, name:String):ShaderNode {
	return nodeObject(new PropertyNode(type, name, true));
}

export var diffuseColor:ShaderNode = nodeImmutable(PropertyNode, 'vec4', 'DiffuseColor');
export var roughness:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Roughness');
export var metalness:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Metalness');
export var clearcoat:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Clearcoat');
export var clearcoatRoughness:ShaderNode = nodeImmutable(PropertyNode, 'float', 'ClearcoatRoughness');
export var sheen:ShaderNode = nodeImmutable(PropertyNode, 'vec3', 'Sheen');
export var sheenRoughness:ShaderNode = nodeImmutable(PropertyNode, 'float', 'SheenRoughness');
export var iridescence:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Iridescence');
export var iridescenceIOR:ShaderNode = nodeImmutable(PropertyNode, 'float', 'IridescenceIOR');
export var iridescenceThickness:ShaderNode = nodeImmutable(PropertyNode, 'float', 'IridescenceThickness');
export var alphaT:ShaderNode = nodeImmutable(PropertyNode, 'float', 'AlphaT');
export var anisotropy:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Anisotropy');
export var anisotropyT:ShaderNode = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyT');
export var anisotropyB:ShaderNode = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyB');
export var specularColor:ShaderNode = nodeImmutable(PropertyNode, 'color', 'SpecularColor');
export var specularF90:ShaderNode = nodeImmutable(PropertyNode, 'float', 'SpecularF90');
export var shininess:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Shininess');
export var output:ShaderNode = nodeImmutable(PropertyNode, 'vec4', 'Output');
export var dashSize:ShaderNode = nodeImmutable(PropertyNode, 'float', 'dashSize');
export var gapSize:ShaderNode = nodeImmutable(PropertyNode, 'float', 'gapSize');
export var pointWidth:ShaderNode = nodeImmutable(PropertyNode, 'float', 'pointWidth');
export var ior:ShaderNode = nodeImmutable(PropertyNode, 'float', 'IOR');
export var transmission:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Transmission');
export var thickness:ShaderNode = nodeImmutable(PropertyNode, 'float', 'Thickness');
export var attenuationDistance:ShaderNode = nodeImmutable(PropertyNode, 'float', 'AttenuationDistance');
export var attenuationColor:ShaderNode = nodeImmutable(PropertyNode, 'color', 'AttenuationColor');

addNodeClass('PropertyNode', PropertyNode);