import Node from './Node.hx';

class PropertyNode extends Node {
	public var name:String;
	public var varying:Bool;

	public function new(nodeType:String, name:String = null, varying:Bool = false) {
		super(nodeType);
		this.name = name;
		this.varying = varying;
		this.isPropertyNode = true;
	}

	public function getHash(builder:Dynamic) -> Int {
		if (this.name != null) {
			return this.name.hashCode();
		} else {
			return super.getHash(builder);
		}
	}

	public function isGlobal(/*builder:Dynamic*/) -> Bool {
		return true;
	}

	public function generate(builder:Dynamic) -> String {
		var nodeVar = null;
		if (this.varying) {
			nodeVar = builder.getVaryingFromNode(this, this.name);
			nodeVar.needsInterpolation = true;
		} else {
			nodeVar = builder.getVarFromNode(this, this.name);
		}
		return builder.getPropertyName(nodeVar);
	}
}

function property(type:String, name:String) -> Dynamic {
	return nodeObject(new PropertyNode(type, name));
}

function varyingProperty(type:String, name:String) -> Dynamic {
	return nodeObject(new PropertyNode(type, name, true));
}

var diffuseColor = nodeImmutable(PropertyNode, 'vec4', 'DiffuseColor');
var roughness = nodeImmutable(PropertyNode, 'float', 'Roughness');
var metalness = nodeImmutable(PropertyNode, 'float', 'Metalness');
var clearcoat = nodeImmutable(PropertyNode, 'float', 'Clearcoat');
var clearcoatRoughness = nodeImmutable(PropertyNode, 'float', 'ClearcoatRoughness');
var sheen = nodeImmutable(PropertyNode, 'vec3', 'Sheen');
var sheenRoughness = nodeImmutable(PropertyNode, 'float', 'SheenRoughness');
var iridescence = nodeImmutable(PropertyNode, 'float', 'Iridescence');
var iridescenceIOR = nodeImmutable(PropertyNode, 'float', 'IridescenceIOR');
var iridescenceThickness = nodeImmutable(PropertyNode, 'float', 'IridescenceThickness');
var alphaT = nodeImmutable(PropertyNode, 'float', 'AlphaT');
var anisotropy = nodeImmutable(PropertyNode, 'float', 'Anisotropy');
var anisotropyT = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyT');
var anisotropyB = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyB');
var specularColor = nodeImmutable(PropertyNode, 'color', 'SpecularColor');
var specularF90 = nodeImmutable(PropertyNode, 'float', 'SpecularF90');
var shininess = nodeImmutable(PropertyNode, 'float', 'Shininess');
var output = nodeImmutable(PropertyNode, 'vec4', 'Output');
var dashSize = nodeImmutable(PropertyNode, 'float', 'dashSize');
var gapSize = nodeImmutable(PropertyNode, 'float', 'gapSize');
var pointWidth = nodeImmutable(PropertyNode, 'float', 'pointWidth');
var ior = nodeImmutable(PropertyNode, 'float', 'IOR');
var transmission = nodeImmutable(PropertyNode, 'float', 'Transmission');
var thickness = nodeImmutable(PropertyNode, 'float', 'Thickness');
var attenuationDistance = nodeImmutable(PropertyNode, 'float', 'AttenuationDistance');
var attenuationColor = nodeImmutable(PropertyNode, 'color', 'AttenuationColor');

addNodeClass('PropertyNode', PropertyNode);