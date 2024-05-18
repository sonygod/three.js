package three.js.examples.jm.nodes.accessors;

import three.js.core.Node;
import three.js.core.NodeUpdateType;
import three.js.core.UniformNode.uniform;
import three.js.nodes.TextureNode.texture;
import three.js.nodes.BufferNode.buffer;
import three.js.shaderNode.ShaderNode.nodeObject;
import three.js.nodes.UniformsNode.uniforms;
import three.js.utils.ArrayElementNode;

class ReferenceElementNode extends ArrayElementNode {
    public var referenceNode:ReferenceNode;

    public function new(referenceNode:ReferenceNode, indexNode:ArrayElementNode) {
        super(referenceNode, indexNode);
        this.referenceNode = referenceNode;
        this.isReferenceElementNode = true;
    }

    public function getNodeType():String {
        return this.referenceNode.uniformType;
    }

    override public function generate(builder:Dynamic):String {
        var snippet = super.generate(builder);
        var arrayType = this.referenceNode.getNodeType();
        var elementType = this.getNodeType();
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

    public function new(property:String, uniformType:String, object:Dynamic = null, count:Int = 0) {
        super();
        this.property = property;
        this.uniformType = uniformType;
        this.object = object;
        this.count = count;
        this.properties = property.split(".");
        this.updateType = NodeUpdateType.OBJECT;
    }

    public function element(indexNode:ArrayElementNode):Node {
        return nodeObject(new ReferenceElementNode(this, nodeObject(indexNode)));
    }

    public function setNodeType(uniformType:String):Void {
        var node:Node = null;
        if (this.count != null) {
            node = buffer(null, uniformType, this.count);
        } else if (Std.isOfType(this.getValueFromReference(), Array)) {
            node = uniforms(null, uniformType);
        } else if (uniformType == "texture") {
            node = texture(null);
        } else {
            node = uniform(null, uniformType);
        }
        this.node = node;
    }

    public function getNodeType(builder:Dynamic):String {
        return this.node.getNodeType(builder);
    }

    public function getValueFromReference(object:Dynamic = null):Dynamic {
        var value:Dynamic = object != null ? object : this.reference;
        for (property in this.properties) {
            value = Reflect.getProperty(value, property);
        }
        return value;
    }

    public function updateReference(state:Dynamic):Dynamic {
        this.reference = this.object != null ? this.object : state.object;
        return this.reference;
    }

    public function setup():Node {
        this.updateValue();
        return this.node;
    }

    public function update(/*frame*/):Void {
        this.updateValue();
    }

    public function updateValue():Void {
        if (this.node == null) this.setNodeType(this.uniformType);
        var value:Dynamic = this.getValueFromReference();
        if (Std.isOfType(value, Array)) {
            this.node.array = value;
        } else {
            this.node.value = value;
        }
    }
}

class ReferenceNodeTools {
    public static function reference(name:String, type:String, object:Dynamic):Node {
        return nodeObject(new ReferenceNode(name, type, object));
    }

    public static function referenceBuffer(name:String, type:String, count:Int, object:Dynamic):Node {
        return nodeObject(new ReferenceNode(name, type, object, count));
    }
}

Node.addClass("ReferenceNode", ReferenceNode);