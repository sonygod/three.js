package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.constants.NodeShaderStage;

class VaryingNode extends Node {
    public var node:Node;
    public var name:String;
    public var isVaryingNode:Bool = true;

    public function new(node:Node, ?name:String) {
        super();
        this.node = node;
        this.name = name;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getHash(builder:Dynamic):String {
        return if (name != null) name else super.getHash(builder);
    }

    public function getNodeType(builder:Dynamic):String {
        return node.getNodeType(builder);
    }

    public function setupVarying(builder:Dynamic):Dynamic {
        var properties:Dynamic = builder.getNodeProperties(this);
        var varying:Dynamic = properties.varying;
        if (varying == null) {
            var name:String = this.name;
            var type:String = getNodeType(builder);
            properties.varying = varying = builder.getVaryingFromNode(this, name, type);
            properties.node = this.node;
        }
        varying.needsInterpolation ||= (builder.shaderStage == 'fragment');
        return varying;
    }

    public function setup(builder:Dynamic):Void {
        setupVarying(builder);
    }

    public function generate(builder:Dynamic):String {
        var type:String = getNodeType(builder);
        var varying:Dynamic = setupVarying(builder);
        var propertyName:String = builder.getPropertyName(varying, NodeShaderStage.VERTEX);
        builder.flowNodeFromShaderStage(NodeShaderStage.VERTEX, this.node, type, propertyName);
        return builder.getPropertyName(varying);
    }
}

typedef VaryingNodeProxy = VaryingNode;

extern class VaryingNodeProxy {
    public function new(node:Node, ?name:String);
}

// Register node element
three.js.examples.jsm.shadernode.ShaderNode.addNodeElement('varying', VaryingNodeProxy);

// Register node class
Node.addNodeClass('VaryingNode', VaryingNode);