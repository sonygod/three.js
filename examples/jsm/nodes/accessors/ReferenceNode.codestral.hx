import nodes.core.Node;
import nodes.core.NodeUpdateType;
import nodes.core.UniformNode;
import nodes.accessors.TextureNode;
import nodes.accessors.BufferNode;
import nodes.shadernode.ShaderNode;
import nodes.accessors.UniformsNode;
import nodes.utils.ArrayElementNode;

class ReferenceElementNode extends ArrayElementNode {

    public var referenceNode:ReferenceNode;

    public function new(referenceNode:ReferenceNode, indexNode:Node) {
        super(referenceNode, indexNode);
        this.referenceNode = referenceNode;
        this.isReferenceElementNode = true;
    }

    public function getNodeType():String {
        return this.referenceNode.uniformType;
    }

    override public function generate(builder:Builder):String {
        var snippet = super.generate(builder);
        var arrayType = this.referenceNode.getNodeType();
        var elementType = this.getNodeType();
        return builder.format(snippet, arrayType, elementType);
    }
}


File path: three.js/examples/jsm/nodes/accessors/ReferenceNode.hx

import nodes.core.Node;
import nodes.core.NodeUpdateType;
import nodes.core.UniformNode;
import nodes.accessors.TextureNode;
import nodes.accessors.BufferNode;
import nodes.shadernode.ShaderNode;
import nodes.accessors.UniformsNode;
import nodes.accessors.ReferenceElementNode;

class ReferenceNode extends Node {

    public var property:String;
    public var uniformType:String;
    public var object:Dynamic;
    public var count:Int;
    public var properties:Array<String>;
    public var reference:Dynamic;
    public var node:Node;

    public function new(property:String, uniformType:String, object:Dynamic = null, count:Int = null) {
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

    public function element(indexNode:Node):Node {
        return new ShaderNode(new ReferenceElementNode(this, new ShaderNode(indexNode)));
    }

    public function setNodeType(uniformType:String):Void {
        if (this.count != null) {
            this.node = new BufferNode(null, uniformType, this.count);
        } else if (Std.is(this.getValueFromReference(), Array)) {
            this.node = new UniformsNode(null, uniformType);
        } else if (uniformType == 'texture') {
            this.node = new TextureNode(null);
        } else {
            this.node = new UniformNode(null, uniformType);
        }
    }

    public function getNodeType(builder:Builder):String {
        return this.node.getNodeType(builder);
    }

    public function getValueFromReference(object:Dynamic = null):Dynamic {
        if (object == null) object = this.reference;
        var value = Reflect.field(object, this.properties[0]);
        for (var i:Int = 1; i < this.properties.length; i++) {
            value = Reflect.field(value, this.properties[i]);
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
        var value = this.getValueFromReference();
        if (Std.is(value, Array)) {
            this.node.array = value;
        } else {
            this.node.value = value;
        }
    }
}


File path: three.js/examples/jsm/nodes/accessors/NodeClasses.hx

import nodes.core.Node;
import nodes.accessors.ReferenceNode;

class NodeClasses {
    public static function addNodeClass(name:String, nodeClass:Class<Node>):Void {
        // Implementation based on your context
    }
}


File path: three.js/examples/jsm/nodes/accessors/ReferenceNodeUtils.hx

import nodes.shadernode.ShaderNode;
import nodes.accessors.ReferenceNode;

class ReferenceNodeUtils {
    public static function reference(name:String, type:String, object:Dynamic):ShaderNode {
        return new ShaderNode(new ReferenceNode(name, type, object));
    }

    public static function referenceBuffer(name:String, type:String, count:Int, object:Dynamic):ShaderNode {
        return new ShaderNode(new ReferenceNode(name, type, object, count));
    }
}