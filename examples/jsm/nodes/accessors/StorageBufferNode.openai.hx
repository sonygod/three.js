package three.js.examples.jms.nodes.accessors;

import three.js.examples.jms.nodes.BufferNode;
import three.js.examples.jms.nodes.BufferAttributeNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.core.VaryingNode;
import three.js.utils.StorageArrayElementNode;

class StorageBufferNode extends BufferNode {

    public var isStorageBufferNode:Bool;

    public var bufferObject:Bool;

    private var _attribute:BufferAttributeNode;
    private var _varying:VaryingNode;

    public function new(value:Dynamic, bufferType:Dynamic, bufferCount:Int = 0) {
        super(value, bufferType, bufferCount);
        this.isStorageBufferNode = true;
        this.bufferObject = false;
        this._attribute = null;
        this._varying = null;

        if (!value.isStorageBufferAttribute && !value.isStorageInstancedBufferAttribute) {
            // TOOD: Improve it, possibly adding a new property to the BufferAttribute to identify it as a storage buffer read-only attribute in Renderer
            if (value.isInstancedBufferAttribute) value.isStorageInstancedBufferAttribute = true;
            else value.isStorageBufferAttribute = true;
        }
    }

    public function getInputType(builder:Dynamic):String {
        return 'storageBuffer';
    }

    public function element(indexNode:Dynamic):StorageArrayElementNode {
        return storageElement(this, indexNode);
    }

    public function setBufferObject(value:Bool):StorageBufferNode {
        this.bufferObject = value;
        return this;
    }

    public function generate(builder:Dynamic):Dynamic {
        if (builder.isAvailable('storageBuffer')) return super.generate(builder);

        var nodeType = this.getNodeType(builder);

        if (this._attribute == null) {
            this._attribute = bufferAttribute(this.value);
            this._varying = varying(this._attribute);
        }

        var output = this._varying.build(builder, nodeType);

        builder.registerTransform(output, this._attribute);

        return output;
    }

}

// exports
@:keep
	extern class StorageBufferNode extends BufferNode {}

@:keep
	extern function storage(value:Dynamic, type:Dynamic, count:Int = 0):ShaderNode {
    return nodeObject(new StorageBufferNode(value, type, count));
}

@:keep
	extern function storageObject(value:Dynamic, type:Dynamic, count:Int = 0):ShaderNode {
    return nodeObject(new StorageBufferNode(value, type, count).setBufferObject(true));
}

// register node class
Node.addNodeClass('StorageBufferNode', StorageBufferNode);