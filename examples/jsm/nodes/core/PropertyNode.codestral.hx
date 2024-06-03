import Node;
import addNodeClass;
import ShaderNode.nodeImmutable;
import ShaderNode.nodeObject;

class PropertyNode extends Node {

    public var name:String;
    public var varying:Bool;
    public var isPropertyNode:Bool = true;

    public function new(nodeType:String, ?name:String = null, ?varying:Bool = false) {
        super(nodeType);
        this.name = name;
        this.varying = varying;
    }

    override public function getHash(builder:Dynamic):Dynamic {
        return if (this.name != null) this.name else super.getHash(builder);
    }

    public function isGlobal( /*builder*/ ):Bool {
        return true;
    }

    override public function generate(builder:Dynamic):Dynamic {
        var nodeVar:Dynamic;

        if (this.varying) {
            nodeVar = builder.getVaryingFromNode(this, this.name);
            nodeVar.needsInterpolation = true;
        } else {
            nodeVar = builder.getVarFromNode(this, this.name);
        }

        return builder.getPropertyName(nodeVar);
    }
}

class PropertyNodeExports {
    static public function property(type:String, name:String):Dynamic {
        return nodeObject(new PropertyNode(type, name));
    }

    static public function varyingProperty(type:String, name:String):Dynamic {
        return nodeObject(new PropertyNode(type, name, true));
    }

    static public var diffuseColor:Dynamic = nodeImmutable(PropertyNode, 'vec4', 'DiffuseColor');
    static public var roughness:Dynamic = nodeImmutable(PropertyNode, 'float', 'Roughness');
    static public var metalness:Dynamic = nodeImmutable(PropertyNode, 'float', 'Metalness');
    static public var clearcoat:Dynamic = nodeImmutable(PropertyNode, 'float', 'Clearcoat');
    static public var clearcoatRoughness:Dynamic = nodeImmutable(PropertyNode, 'float', 'ClearcoatRoughness');
    static public var sheen:Dynamic = nodeImmutable(PropertyNode, 'vec3', 'Sheen');
    static public var sheenRoughness:Dynamic = nodeImmutable(PropertyNode, 'float', 'SheenRoughness');
    static public var iridescence:Dynamic = nodeImmutable(PropertyNode, 'float', 'Iridescence');
    static public var iridescenceIOR:Dynamic = nodeImmutable(PropertyNode, 'float', 'IridescenceIOR');
    static public var iridescenceThickness:Dynamic = nodeImmutable(PropertyNode, 'float', 'IridescenceThickness');
    static public var alphaT:Dynamic = nodeImmutable(PropertyNode, 'float', 'AlphaT');
    static public var anisotropy:Dynamic = nodeImmutable(PropertyNode, 'float', 'Anisotropy');
    static public var anisotropyT:Dynamic = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyT');
    static public var anisotropyB:Dynamic = nodeImmutable(PropertyNode, 'vec3', 'AnisotropyB');
    static public var specularColor:Dynamic = nodeImmutable(PropertyNode, 'color', 'SpecularColor');
    static public var specularF90:Dynamic = nodeImmutable(PropertyNode, 'float', 'SpecularF90');
    static public var shininess:Dynamic = nodeImmutable(PropertyNode, 'float', 'Shininess');
    static public var output:Dynamic = nodeImmutable(PropertyNode, 'vec4', 'Output');
    static public var dashSize:Dynamic = nodeImmutable(PropertyNode, 'float', 'dashSize');
    static public var gapSize:Dynamic = nodeImmutable(PropertyNode, 'float', 'gapSize');
    static public var pointWidth:Dynamic = nodeImmutable(PropertyNode, 'float', 'pointWidth');
    static public var ior:Dynamic = nodeImmutable(PropertyNode, 'float', 'IOR');
    static public var transmission:Dynamic = nodeImmutable(PropertyNode, 'float', 'Transmission');
    static public var thickness:Dynamic = nodeImmutable(PropertyNode, 'float', 'Thickness');
    static public var attenuationDistance:Dynamic = nodeImmutable(PropertyNode, 'float', 'AttenuationDistance');
    static public var attenuationColor:Dynamic = nodeImmutable(PropertyNode, 'color', 'AttenuationColor');
}

addNodeClass('PropertyNode', PropertyNode);