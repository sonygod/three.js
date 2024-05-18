package three.js.examples.nodes.core;

import three.js.examples.nodes.core.Node;
import three.js.examples.core.constants.NodeShaderStage;

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
        return if (this.name != null) this.name else super.getHash(builder);
    }

    public function getNodeType(builder:Dynamic):String {
        // VaryingNode is auto type
        return this.node.getNodeType(builder);
    }

    public function setupVarying(builder:Dynamic):Dynamic {
        var properties = builder.getNodeProperties(this);
        var varying = properties.varying;

        if (varying == null) {
            var name = this.name;
            var type = this.getNodeType(builder);
            properties.varying = varying = builder.getVaryingFromNode(this, name, type);
            properties.node = this.node;
        }

        // this property can be used to check if the varying can be optimized for a variable
        if (varying.needsInterpolation == null) varying.needsInterpolation = (builder.shaderStage == NodeShaderStage.FRAGMENT);

        return varying;
    }

    public function setup(builder:Dynamic):Void {
        this.setupVarying(builder);
    }

    public function generate(builder:Dynamic):String {
        var type = this.getNodeType(builder);
        var varying = this.setupVarying(builder);

        var propertyName = builder.getPropertyName(varying, NodeShaderStage.VERTEX);

        // force node run in vertex stage
        builder.flowNodeFromShaderStage(NodeShaderStage.VERTEX, this.node, type, propertyName);

        return builder.getPropertyName(varying);
    }
}

class VaryingNodeProxy {
    public static function nodeProxy(node:VaryingNode):VaryingNode {
        return node;
    }
}

// register node
Node.addNodeElement('varying', VaryingNodeProxy.nodeProxy(new VaryingNode(null)));
Node.addNodeClass('VaryingNode', VaryingNode);