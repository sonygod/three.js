package three.js.nodes.accessors;

import three.js.core.Node;
import three.js.core.NodeUpdateType;
import three.js.utils.ArrayElementNode;
import three.js.shadernode.ShaderNode;
import three.js.nodes.TextureNode;
import three.js.nodes.BufferNode;
import three.js.nodes.UniformsNode;

class ReferenceElementNode extends ArrayElementNode {
    public var referenceNode:ReferenceNode;

    public function new(referenceNode:ReferenceNode, indexNode:ArrayElementNode) {
        super(referenceNode, indexNode);
        this.referenceNode = referenceNode;
        this.isReferenceElementNode = true;
    }

    public function getNodeType():String {
        return referenceNode.uniformType;
    }

    override public function generate(builder:Dynamic):String {
        var snippet = super.generate(builder);
        var arrayType = referenceNode.getNodeType();
        var elementType = getNodeType();
        return builder.format(snippet, arrayType, elementType);
    }
}

class ReferenceNode extends Node {
    public var property:String;
    public var uniformType:String;
    public var object:Dynamic;
    public var count:Int;
    public var properties:Array<String>;
    public var reference:Dynamic;
    public var node:Node;
    public var updateType:NodeUpdateType;

    public function new(property:String, uniformType:String, object:Dynamic = null, count:Int = 0) {
        super();
        this.property = property;
        this.uniformType = uniformType;
        this.object = object;
        this.count = count;
        this.properties = property.split('.');
        this.reference = null;
        this.node = null;
        this.updateType = NodeUpdateType.OBJECT;
    }

    public function element(indexNode:ArrayElementNode):Node {
        return ShaderNode.nodeObject(new ReferenceElementNode(this, ShaderNode.nodeObject(indexNode)));
    }

    public function setNodeType(uniformType:String) {
        var node:Node = null;
        if (this.count != null) {
            node = BufferNode.Buffer(null, uniformType, this.count);
        } else if (Std.isOfType(getValueFromReference(), Array)) {
            node = UniformsNode.Uniforms(null, uniformType);
        } else if (uniformType == 'texture') {
            node = TextureNode.Texture(null);
        } else {
            node = UniformNode.Uniform(null, uniformType);
        }
        this.node = node;
    }

    public function getNodeType(builder:Dynamic):String {
        return node.getNodeType(builder);
    }

    public function getValueFromReference(object:Dynamic = null):Dynamic {
        var properties:Array<String> = this.properties;
        var value:Dynamic = object != null ? object : reference;
        for (i in 1...properties.length) {
            value = value[properties[i]];
        }
        return value;
    }

    public function updateReference(state:Dynamic):Dynamic {
        this.reference = object != null ? object : state.object;
        return this.reference;
    }

    public function setup():Node {
        updateValue();
        return node;
    }

    public function update(frame:Dynamic):Void {
        updateValue();
    }

    public function updateValue():Void {
        if (node == null) setNodeType(uniformType);
        var value:Dynamic = getValueFromReference();
        if (Std.isOfType(value, Array)) {
            node.array = value;
        } else {
            node.value = value;
        }
    }
}

class ReferenceNodeCreator {
    public static function reference(name:String, type:String, object:Dynamic):Node {
        return ShaderNode.nodeObject(new ReferenceNode(name, type, object));
    }

    public static function referenceBuffer(name:String, type:String, count:Int, object:Dynamic):Node {
        return ShaderNode.nodeObject(new ReferenceNode(name, type, object, count));
    }
}

Node.addNodeClass('ReferenceNode', ReferenceNode);