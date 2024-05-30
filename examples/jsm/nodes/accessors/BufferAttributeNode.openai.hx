package three.js.examples.javascript.nodes.accessors;

import three.js.core.InputNode;
import three.js.core.Node;
import three.js.core.VaryingNode;
import three.js.shadernode.ShaderNode;

import three.js.three.InterleavedBuffer;
import three.js.three.InterleavedBufferAttribute;
import three.js.three.StaticDrawUsage;
import three.js.three.DynamicDrawUsage;

class BufferAttributeNode extends InputNode {

    public var isBufferNode:Bool = true;

    public var bufferType:Dynamic;
    public var bufferStride:Int;
    public var bufferOffset:Int;

    public var usage:Dynamic;
    public var instanced:Bool;

    public var attribute:Dynamic;

    public function new(value:Dynamic, ?bufferType:Dynamic, bufferStride:Int = 0, bufferOffset:Int = 0) {
        super(value, bufferType);

        this.bufferType = bufferType;
        this.bufferStride = bufferStride;
        this.bufferOffset = bufferOffset;

        this.usage = StaticDrawUsage;
        this.instanced = false;

        this.attribute = null;

        if (value != null && value.isBufferAttribute == true) {
            this.attribute = value;
            this.usage = value.usage;
            this.instanced = value.isInstancedBufferAttribute;
        }
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        if (this.bufferType == null) {
            this.bufferType = builder.getTypeFromAttribute(this.attribute);
        }
        return this.bufferType;
    }

    public function setup(builder:Dynamic):Void {
        if (this.attribute != null) return;

        var type = this.getNodeType(builder);
        var array = this.value;
        var itemSize = builder.getTypeLength(type);
        var stride = this.bufferStride != 0 ? this.bufferStride : itemSize;
        var offset = this.bufferOffset;

        var buffer = if (array.isInterleavedBuffer) array else new InterleavedBuffer(array, stride);
        var bufferAttribute = new InterleavedBufferAttribute(buffer, itemSize, offset);

        buffer.setUsage(this.usage);

        this.attribute = bufferAttribute;
        this.attribute.isInstancedBufferAttribute = this.instanced; // @TODO: Add a possible: InstancedInterleavedBufferAttribute
    }

    public function generate(builder:Dynamic):Dynamic {
        var nodeType = this.getNodeType(builder);

        var nodeAttribute = builder.getBufferAttributeFromNode(this, nodeType);
        var propertyName = builder.getPropertyName(nodeAttribute);

        var output:Dynamic = null;

        if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
            this.name = propertyName;

            output = propertyName;

        } else {
            var nodeVarying = VaryingNode.varying(this);

            output = nodeVarying.build(builder, nodeType);
        }

        return output;
    }

    public function getInputType(/*builder*/):String {
        return 'bufferAttribute';
    }

    public function setUsage(value:Dynamic):BufferAttributeNode {
        this.usage = value;

        return this;
    }

    public function setInstanced(value:Bool):BufferAttributeNode {
        this.instanced = value;

        return this;
    }
}

// Export
extern class BufferAttributeNode {
    public static function bufferAttribute(array:Dynamic, type:Dynamic, stride:Int = 0, offset:Int = 0):BufferAttributeNode {
        return nodeObject(new BufferAttributeNode(array, type, stride, offset));
    }

    public static function dynamicBufferAttribute(array:Dynamic, type:Dynamic, stride:Int = 0, offset:Int = 0):BufferAttributeNode {
        return bufferAttribute(array, type, stride, offset).setUsage(DynamicDrawUsage);
    }

    public static function instancedBufferAttribute(array:Dynamic, type:Dynamic, stride:Int = 0, offset:Int = 0):BufferAttributeNode {
        return bufferAttribute(array, type, stride, offset).setInstanced(true);
    }

    public static function instancedDynamicBufferAttribute(array:Dynamic, type:Dynamic, stride:Int = 0, offset:Int = 0):BufferAttributeNode {
        return dynamicBufferAttribute(array, type, stride, offset).setInstanced(true);
    }
}

// Register node element
ShaderNode.addNodeElement('toAttribute', function(bufferNode:BufferAttributeNode) {
    return bufferAttribute(bufferNode.value);
});

// Register node class
Node.addNodeClass('BufferAttributeNode', BufferAttributeNode);