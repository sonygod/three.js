import BufferNode from "./BufferNode";
import BufferAttributeNode from "./BufferAttributeNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import VaryingNode from "../core/VaryingNode";
import StorageArrayElementNode from "../utils/StorageArrayElementNode";

class StorageBufferNode extends BufferNode {
	public isStorageBufferNode:Bool = true;
	public bufferObject:Bool = false;
	private _attribute:BufferAttributeNode = null;
	private _varying:VaryingNode = null;

	public function new(value:Dynamic, bufferType:String, bufferCount:Int = 0) {
		super(value, bufferType, bufferCount);

		if (!Reflect.hasField(value, "isStorageBufferAttribute") && !Reflect.hasField(value, "isStorageInstancedBufferAttribute")) {
			// TOOD: Improve it, possibly adding a new property to the BufferAttribute to identify it as a storage buffer read-only attribute in Renderer

			if (Reflect.hasField(value, "isInstancedBufferAttribute")) Reflect.setField(value, "isStorageInstancedBufferAttribute", true);
			else Reflect.setField(value, "isStorageBufferAttribute", true);
		}
	}

	public function getInputType(builder:Dynamic):String {
		return "storageBuffer";
	}

	public function element(indexNode:Dynamic):Dynamic {
		return StorageArrayElementNode.storageElement(this, indexNode);
	}

	public function setBufferObject(value:Bool):StorageBufferNode {
		this.bufferObject = value;
		return this;
	}

	public function generate(builder:Dynamic):Dynamic {
		if (builder.isAvailable("storageBuffer")) return super.generate(builder);

		var nodeType:String = this.getNodeType(builder);

		if (this._attribute == null) {
			this._attribute = BufferAttributeNode.bufferAttribute(this.value);
			this._varying = VaryingNode.varying(this._attribute);
		}

		var output:Dynamic = this._varying.build(builder, nodeType);

		builder.registerTransform(output, this._attribute);

		return output;
	}
}

export var storage = function(value:Dynamic, type:String, count:Int = 0):Dynamic {
	return ShaderNode.nodeObject(new StorageBufferNode(value, type, count));
}

export var storageObject = function(value:Dynamic, type:String, count:Int = 0):Dynamic {
	return ShaderNode.nodeObject(new StorageBufferNode(value, type, count).setBufferObject(true));
}

Node.addNodeClass("StorageBufferNode", StorageBufferNode);