package three.js.examples.jm.nodes.accessors;

import three.js.examples.jm.nodes.BufferNode;
import three.js.examples.jm.nodes.BufferAttributeNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.core.VaryingNode;
import three.js.utils.StorageArrayElementNode;

class StorageBufferNode extends BufferNode {

    public var isStorageBufferNode:Bool = true;

    public var bufferObject:Bool = false;

    private var _attribute:BufferAttributeNode;
    private var _varying:VaryingNode;

    public function new(value:Dynamic, bufferType:String, bufferCount:Int = 0) {
        super(value, bufferType, bufferCount);

        if (!value.isStorageBufferAttribute && !value.isStorageInstancedBufferAttribute) {
            if (value.isInstancedBufferAttribute) {
                Reflect.setField(value, "isStorageInstancedBufferAttribute", true);
            } else {
                Reflect.setField(value, "isStorageBufferAttribute", true);
            }
        }
    }

    public function getInputType(builder:Dynamic):String {
        return 'storageBuffer';
    }

    public function element(indexNode:Dynamic):StorageArrayElementNode {
        return StorageArrayElementNode.storageElement(this, indexNode);
    }

    public function setBufferObject(value:Bool):StorageBufferNode {
        bufferObject = value;
        return this;
    }

    public function generate(builder:Dynamic):Dynamic {
        if (builder.isAvailable('storageBuffer')) {
            return super.generate(builder);
        }

        var nodeType = getNodeType(builder);

        if (_attribute == null) {
            _attribute = BufferAttributeNode.bufferAttribute(value);
            _varying = VaryingNode.varying(_attribute);
        }

        var output = _varying.build(builder, nodeType);
        builder.registerTransform(output, _attribute);
        return output;
    }

    static public function add():Void {
        Node.addNodeClass('StorageBufferNode', StorageBufferNode);
    }
}

class StorageBufferNodeUtils {
    public static function storage(value:Dynamic, type:String, count:Int = 0):ShaderNode {
        return ShaderNode.nodeObject(new StorageBufferNode(value, type, count));
    }

    public static function storageObject(value:Dynamic, type:String, count:Int = 0):ShaderNode {
        return ShaderNode.nodeObject(new StorageBufferNode(value, type, count).setBufferObject(true));
    }
}