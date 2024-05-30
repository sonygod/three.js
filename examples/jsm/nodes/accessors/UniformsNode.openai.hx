package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.shaderNode.ShaderNode;
import three.js.core.constants.NodeUpdateType;
import three.js.core.NodeUtils;
import three.js.utils.ArrayElementNode;
import three.js.nodes.BufferNode;

class UniformsElementNode extends ArrayElementNode {
    public var isArrayBufferElementNode:Bool;

    public function new(arrayBuffer:Dynamic, indexNode:Node) {
        super(arrayBuffer, indexNode);
        this.isArrayBufferElementNode = true;
    }

    public function getNodeType(builder:Dynamic):String {
        return this.node.getElementType(builder);
    }

    public function generate(builder:Dynamic):String {
        var snippet = super.generate(builder);
        var type = this.getNodeType();
        return builder.format(snippet, 'vec4', type);
    }
}

class UniformsNode extends BufferNode {
    public var array:Array<Dynamic>;
    public var elementType:String;
    public var _elementType:String;
    public var _elementLength:Int;
    public var updateType:Int;
    public var isArrayBufferNode:Bool;

    public function new(value:Array<Dynamic>, elementType:String = null) {
        super(null, 'vec4');
        this.array = value;
        this.elementType = elementType;
        this._elementType = null;
        this._elementLength = 0;
        this.updateType = NodeUpdateType.RENDER;
        this.isArrayBufferNode = true;
    }

    public function getElementType():String {
        return this.elementType != null ? this.elementType : this._elementType;
    }

    public function getElementLength():Int {
        return this._elementLength;
    }

    public function update(frame:Dynamic) {
        var array:Array<Dynamic> = this.array;
        var value:Array<Float> = this.value;
        var elementLength:Int = this.getElementLength();
        var elementType:String = this.getElementType();

        if (elementLength == 1) {
            for (i in 0...array.length) {
                var index:Int = i * 4;
                value[index] = array[i];
            }
        } else if (elementType == 'color') {
            for (i in 0...array.length) {
                var index:Int = i * 4;
                var vector:Dynamic = array[i];
                value[index] = vector.r;
                value[index + 1] = vector.g;
                value[index + 2] = vector.b != null ? vector.b : 0;
                //value[index + 3] = vector.a != null ? vector.a : 0;
            }
        } else {
            for (i in 0...array.length) {
                var index:Int = i * 4;
                var vector:Dynamic = array[i];
                value[index] = vector.x;
                value[index + 1] = vector.y;
                value[index + 2] = vector.z != null ? vector.z : 0;
                value[index + 3] = vector.w != null ? vector.w : 0;
            }
        }
    }

    public function setup(builder:Dynamic):Void {
        var length:Int = this.array.length;
        this._elementType = this.elementType == null ? NodeUtils.getValueType(this.array[0]) : this.elementType;
        this._elementLength = builder.getTypeLength(this._elementType);
        this.value = new Float32Array(length * 4);
        this.bufferCount = length;
        super.setup(builder);
    }

    public function element(indexNode:Node):Node {
        return ShaderNode(nodeObject(new UniformsElementNode(this, nodeObject(indexNode))));
    }
}

extern class Node {
    public function getElementLength(builder:Dynamic):Int;
}

extern class ShaderNode {
    public function new(node:Node);
    public static function nodeObject(node:Node):ShaderNode;
}

extern class BufferNode {
    public function setup(builder:Dynamic):Void;
}

extern class NodeUtils {
    public static function getValueType(value:Dynamic):String;
}

extern class ArrayElementNode {
    public function generate(builder:Dynamic):String;
}

extern class NodeUpdateType {
    public static var RENDER:Int;
}

extern class NodeObject {
    public static function nodeObject(node:Node);
}

extern class Uniforms {
    public static function.uniforms(values:Array<Dynamic>, nodeType:String):UniformsNode;
}

Uniforms.uniforms = function(values:Array<Dynamic>, nodeType:String):UniformsNode {
    return ShaderNode(nodeObject(new UniformsNode(values, nodeType)));
};

Node.addNodeClass('UniformsNode', UniformsNode);