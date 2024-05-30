package three.js.examples.jm.nodes.core;

import Node;
import ShaderNode;

class PropertyNode extends Node {
    public var name:String;
    public var varying:Bool;

    public function new(nodeType:String, ?name:String, varying:Bool = false) {
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

private function nodeObject(node:PropertyNode):Dynamic {
    return node;
}

private function nodeImmutable<T>(type:String, name:String):T {
    return nodeObject(new PropertyNode(type, name));
}

@:forward static function property(type:String, name:String):PropertyNode {
    return nodeObject(new PropertyNode(type, name));
}

@:forward static function varyingProperty(type:String, name:String):PropertyNode {
    return nodeObject(new PropertyNode(type, name, true));
}

@:forward static var diffuseColor:PropertyNode = nodeImmutable('vec4', 'DiffuseColor');
@:forward static var roughness:PropertyNode = nodeImmutable('float', 'Roughness');
@:forward static var metalness:PropertyNode = nodeImmutable('float', 'Metalness');
@:forward static var clearcoat:PropertyNode = nodeImmutable('float', 'Clearcoat');
@:forward static var clearcoatRoughness:PropertyNode = nodeImmutable('float', 'ClearcoatRoughness');
@:forward static var sheen:PropertyNode = nodeImmutable('vec3', 'Sheen');
@:forward static var sheenRoughness:PropertyNode = nodeImmutable('float', 'SheenRoughness');
@:forward static var iridescence:PropertyNode = nodeImmutable('float', 'Iridescence');
@:forward static var iridescenceIOR:PropertyNode = nodeImmutable('float', 'IridescenceIOR');
@:forward static var iridescenceThickness:PropertyNode = nodeImmutable('float', 'IridescenceThickness');
@:forward static var alphaT:PropertyNode = nodeImmutable('float', 'AlphaT');
@:forward static var anisotropy:PropertyNode = nodeImmutable('float', 'Anisotropy');
@:forward static var anisotropyT:PropertyNode = nodeImmutable('vec3', 'AnisotropyT');
@:forward static var anisotropyB:PropertyNode = nodeImmutable('vec3', 'AnisotropyB');
@:forward static var specularColor:PropertyNode = nodeImmutable('color', 'SpecularColor');
@:forward static var specularF90:PropertyNode = nodeImmutable('float', 'SpecularF90');
@:forward static var shininess:PropertyNode = nodeImmutable('float', 'Shininess');
@:forward static var output:PropertyNode = nodeImmutable('vec4', 'Output');
@:forward static var dashSize:PropertyNode = nodeImmutable('float', 'dashSize');
@:forward static var gapSize:PropertyNode = nodeImmutable('float', 'gapSize');
@:forward static var pointWidth:PropertyNode = nodeImmutable('float', 'pointWidth');
@:forward static var ior:PropertyNode = nodeImmutable('float', 'IOR');
@:forward static var transmission:PropertyNode = nodeImmutable('float', 'Transmission');
@:forward static var thickness:PropertyNode = nodeImmutable('float', 'Thickness');
@:forward static var attenuationDistance:PropertyNode = nodeImmutable('float', 'AttenuationDistance');
@:forward static var attenuationColor:PropertyNode = nodeImmutable('color', 'AttenuationColor');

Node.addNodeClass('PropertyNode', PropertyNode);