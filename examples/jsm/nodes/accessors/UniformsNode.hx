package three.js.examples.jm.nodes.accessors;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.core.constants.NodeUpdateType;
import three.js.core.NodeUtils;
import three.js.utils.ArrayElementNode;
import three.js.nodes.accessors.BufferNode;

class UniformsElementNode extends ArrayElementNode {
    public var isArrayBufferElementNode:Bool = true;

    public function new(arrayBuffer:Dynamic, indexNode:Node) {
        super(arrayBuffer, indexNode);
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return node.getElementType(builder);
    }

    public function generate(builder:Dynamic):String {
        var snippet:String = super.generate(builder);
        var type:Dynamic = getNodeType();
        return builder.format(snippet, 'vec4', type);
    }
}

class UniformsNode extends BufferNode {
    public var array:Dynamic;
    public var elementType:Dynamic;
    public var _elementType:Dynamic;
    public var _elementLength:Int;
    public var updateType:NodeUpdateType;
    public var isArrayBufferNode:Bool;

    public function new(value:Dynamic, elementType:Dynamic = null) {
        super(null, 'vec4');
        this.array = value;
        this.elementType = elementType;
        this._elementType = null;
        this._elementLength = 0;
        this.updateType = NodeUpdateType.RENDER;
        this.isArrayBufferNode = true;
    }

    public function getElementType():Dynamic {
        return elementType != null ? elementType : _elementType;
    }

    public function getElementLength():Int {
        return _elementLength;
    }

    public function update(frame:Dynamic):Void {
        var elementLength:Int = getElementLength();
        var elementType:Dynamic = getElementType();
        var array:Array<Dynamic> = this.array;
        var value:Array<Float> = [];

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
                value[index + 2] = vector.b == null ? 0 : vector.b;
            }
        } else {
            for (i in 0...array.length) {
                var index:Int = i * 4;
                var vector:Dynamic = array[i];
                value[index] = vector.x;
                value[index + 1] = vector.y;
                value[index + 2] = vector.z == null ? 0 : vector.z;
                value[index + 3] = vector.w == null ? 0 : vector.w;
            }
        }
    }

    public function setup(builder:Dynamic):Void {
        var length:Int = array.length;
        _elementType = elementType == null ? NodeUtils.getValueType(array[0]) : elementType;
        _elementLength = builder.getTypeLength(_elementType);
        value = new Float32Array(length * 4);
        bufferCount = length;
        super.setup(builder);
    }

    public function element(indexNode:Node):Node {
        return ShaderNode.nodeObject(new UniformsElementNode(this, ShaderNode.nodeObject(indexNode)));
    }
}

class Uniforms {
    public static function uniforms(values:Dynamic, nodeType:Dynamic):Node {
        return ShaderNode.nodeObject(new UniformsNode(values, nodeType));
    }
}

Node.addNodeClass('UniformsNode', UniformsNode);