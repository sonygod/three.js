import BufferNode from 'three.js.nodes.BufferNode';
import { bufferAttribute } from 'three.js.nodes.BufferAttributeNode';
import { addNodeClass } from 'three.js.nodes.core.Node';
import { nodeObject } from 'three.js.nodes.shadernode.ShaderNode';
import { varying } from 'three.js.nodes.core.VaryingNode';
import { storageElement } from 'three.js.nodes.utils.StorageArrayElementNode';

// Placeholder classes for three.js classes not available in Haxe
class BufferAttribute {
    public var isStorageBufferAttribute:Bool = false;
    public var isStorageInstancedBufferAttribute:Bool = false;
    public var isInstancedBufferAttribute:Bool = false;

    public function new() {}
}

class NodeBuilder {
    public function isAvailable(type:String):Bool {
        return true;
    }

    public function registerTransform(output:String, attribute:BufferAttribute) {

    }

    public function new() {}
}

class StorageBufferNode extends BufferNode {

    public var isStorageBufferNode:Bool = false;
    public var bufferObject:Bool = false;
    public var _attribute:BufferAttribute = null;
    public var _varying:String = null;

    public function new(value:BufferAttribute, bufferType:String, bufferCount:Int = 0) {

        super(value, bufferType, bufferCount);

        this.isStorageBufferNode = true;

        this.bufferObject = false;

        this._attribute = null;
        this._varying = null;

        if (value.isStorageBufferAttribute !== true && value.isStorageInstancedBufferAttribute !== true) {

            // TOOD: Improve it, possibly adding a new property to the BufferAttribute to identify it as a storage buffer read-only attribute in Renderer

            if (value.isInstancedBufferAttribute)
                value.isStorageInstancedBufferAttribute = true;
            else
                value.isStorageBufferAttribute = true;
        }
    }

    public function getInputType():String {

        return 'storageBuffer';

    }

    public function element(indexNode:Int):String {

        return storageElement(this, indexNode);

    }

    public function setBufferObject(value:Bool):StorageBufferNode {

        this.bufferObject = value;

        return this;

    }

    public function generate(builder:NodeBuilder):String {

        if (builder.isAvailable('storageBuffer')) return super.generate(builder);

        const nodeType = this.getNodeType(builder);

        if (this._attribute === null) {

            this._attribute = bufferAttribute(this.value);
            this._varying = varying(this._attribute);

        }

        const output = this._varying.build(builder, nodeType);

        builder.registerTransform(output, this._attribute);

        return output;

    }

}

function storage(value:BufferAttribute, type:String, count:Int):String {
    return nodeObject(new StorageBufferNode(value, type, count));
}

function storageObject(value:BufferAttribute, type:String, count:Int):String {
    return nodeObject(new StorageBufferNode(value, type, count).setBufferObject(true));
}

addNodeClass('StorageBufferNode', StorageBufferNode);