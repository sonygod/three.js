package three.js.examples.jm.nodes.core;

import Node;
import ShaderNode;

class PropertyNode extends Node {

    public var name:String;
    public var varying:Bool;

    public function new(nodeType:String, name:String = null, varying:Bool = false) {
        super(nodeType);
        this.name = name;
        this.varying = varying;
        this.isPropertyNode = true;
    }

    override public function getHash(builder:Dynamic):String {
        return if (name != null) name else super.getHash(builder);
    }

    public function isGlobal(builder:Dynamic):Bool {
        return true;
    }

    public function generate(builder:Dynamic):String {
        var nodeVar:Dynamic;
        if (varying) {
            nodeVar = builder.getVaryingFromNode(this, name);
            nodeVar.needsInterpolation = true;
        } else {
            nodeVar = builder.getVarFromNode(this, name);
        }
        return builder.getPropertyName(nodeVar);
    }
}

class PropertyNodeBuilder {
    public static function property(type:String, name:String):ShaderNode {
        return nodeObject(new PropertyNode(type, name));
    }

    public static function varyingProperty(type:String, name:String):ShaderNode {
        return nodeObject(new PropertyNode(type, name, true));
    }
}

// exports
var diffuseColor = nodeImmutable(new PropertyNode('vec4', 'DiffuseColor'));
var roughness = nodeImmutable(new PropertyNode('float', 'Roughness'));
var metalness = nodeImmutable(new PropertyNode('float', 'Metalness'));
var clearcoat = nodeImmutable(new PropertyNode('float', 'Clearcoat'));
var clearcoatRoughness = nodeImmutable(new PropertyNode('float', 'ClearcoatRoughness'));
var sheen = nodeImmutable(new PropertyNode('vec3', 'Sheen'));
var sheenRoughness = nodeImmutable(new PropertyNode('float', 'SheenRoughness'));
var iridescence = nodeImmutable(new PropertyNode('float', 'Iridescence'));
var iridescenceIOR = nodeImmutable(new PropertyNode('float', 'IridescenceIOR'));
var iridescenceThickness = nodeImmutable(new PropertyNode('float', 'IridescenceThickness'));
var alphaT = nodeImmutable(new PropertyNode('float', 'AlphaT'));
var anisotropy = nodeImmutable(new PropertyNode('float', 'Anisotropy'));
var anisotropyT = nodeImmutable(new PropertyNode('vec3', 'AnisotropyT'));
var anisotropyB = nodeImmutable(new PropertyNode('vec3', 'AnisotropyB'));
var specularColor = nodeImmutable(new PropertyNode('color', 'SpecularColor'));
var specularF90 = nodeImmutable(new PropertyNode('float', 'SpecularF90'));
var shininess = nodeImmutable(new PropertyNode('float', 'Shininess'));
var output = nodeImmutable(new PropertyNode('vec4', 'Output'));
var dashSize = nodeImmutable(new PropertyNode('float', 'dashSize'));
var gapSize = nodeImmutable(new PropertyNode('float', 'gapSize'));
var pointWidth = nodeImmutable(new PropertyNode('float', 'pointWidth'));
var ior = nodeImmutable(new PropertyNode('float', 'IOR'));
var transmission = nodeImmutable(new PropertyNode('float', 'Transmission'));
var thickness = nodeImmutable(new PropertyNode('float', 'Thickness'));
var attenuationDistance = nodeImmutable(new PropertyNode('float', 'AttenuationDistance'));
var attenuationColor = nodeImmutable(new PropertyNode('color', 'AttenuationColor'));

addNodeClass('PropertyNode', PropertyNode);