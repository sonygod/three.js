package three.js.examples.jit.nodes.accessors;

import three.js.core.InputNode;
import three.js.core.Node;
import three.js.core.VaryingNode;
import three.js.shadernode.ShaderNode;

import three.js.Three;

class BufferAttributeNode extends InputNode {

    public var bufferType:Null<Int>;
    public var bufferStride:Int;
    public var bufferOffset:Int;
    public var usage:Int;
    public var instanced:Bool;
    public var attribute:InterleavedBufferAttribute;

    public function new(value:Array<Dynamic>, bufferType:Int = null, bufferStride:Int = 0, bufferOffset:Int = 0) {
        super(value, bufferType);
        this.bufferType = bufferType;
        this.bufferStride = bufferStride;
        this.bufferOffset = bufferOffset;
        this.usage = Three.StaticDrawUsage;
        this.instanced = false;
        this.attribute = null;

        if (value != null && value.isBufferAttribute) {
            this.attribute = value;
            this.usage = value.usage;
            this.instanced = value.isInstancedBufferAttribute;
        }
    }

    override public function getNodeType(builder:Dynamic):Int {
        if (this.bufferType == null) {
            this.bufferType = builder.getTypeFromAttribute(this.attribute);
        }
        return this.bufferType;
    }

    override public function setup(builder:Dynamic) {
        if (this.attribute != null) return;
        var type:Int = this.getNodeType(builder);
        var array:Array<Dynamic> = this.value;
        var itemSize:Int = builder.getTypeLength(type);
        var stride:Int = this.bufferStride != 0 ? this.bufferStride : itemSize;
        var offset:Int = this.bufferOffset;

        var buffer:InterleavedBuffer = array.isInterleavedBuffer ? array : new InterleavedBuffer(array, stride);
        this.attribute = new InterleavedBufferAttribute(buffer, itemSize, offset);
        buffer.setUsage(this.usage);
        this.attribute.isInstancedBufferAttribute = this.instanced;
    }

    override public function generate(builder:Dynamic):String {
        var nodeType:Int = this.getNodeType(builder);
        var nodeAttribute:InterleavedBufferAttribute = builder.getBufferAttributeFromNode(this, nodeType);
        var propertyName:String = builder.getPropertyName(nodeAttribute);

        var output:String = null;
        if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
            this.name = propertyName;
            output = propertyName;
        } else {
            var nodeVarying:VaryingNode = VaryingNode.varying(this);
            output = nodeVarying.build(builder, nodeType);
        }
        return output;
    }

    override public function getInputType(/*builder:Dynamic*/):String {
        return 'bufferAttribute';
    }

    public function setUsage(value:Int):BufferAttributeNode {
        this.usage = value;
        return this;
    }

    public function setInstanced(value:Bool):BufferAttributeNode {
        this.instanced = value;
        return this;
    }
}

class BufferAttributeNodeTools {
    public static function bufferAttribute(array:Array<Dynamic>, type:Int, stride:Int, offset:Int):BufferAttributeNode {
        return new BufferAttributeNode(array, type, stride, offset);
    }

    public static function dynamicBufferAttribute(array:Array<Dynamic>, type:Int, stride:Int, offset:Int):BufferAttributeNode {
        return bufferAttribute(array, type, stride, offset).setUsage(Three.DynamicDrawUsage);
    }

    public static function instancedBufferAttribute(array:Array<Dynamic>, type:Int, stride:Int, offset:Int):BufferAttributeNode {
        return bufferAttribute(array, type, stride, offset).setInstanced(true);
    }

    public static function instancedDynamicBufferAttribute(array:Array<Dynamic>, type:Int, stride:Int, offset:Int):BufferAttributeNode {
        return dynamicBufferAttribute(array, type, stride, offset).setInstanced(true);
    }
}

ShaderNode.addNodeElement('toAttribute', function(bufferNode:BufferAttributeNode) {
    return bufferAttribute(bufferNode.value);
});

Node.addNodeClass('BufferAttributeNode', BufferAttributeNode);