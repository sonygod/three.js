import BufferNode from './BufferNode.hx';
import { bufferAttribute } from './BufferAttributeNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { nodeObject } from '../shadernode/ShaderNode.hx';
import { varying } from '../core/VaryingNode.hx';
import { storageElement } from '../utils/StorageArrayElementNode.hx';

class StorageBufferNode extends BufferNode {

	public var isStorageBufferNode:Bool = true;
	public var bufferObject:Bool = false;
	public var _attribute:Null<Dynamic> = null;
	public var _varying:Null<Dynamic> = null;

	public function new(value:Dynamic, bufferType:Dynamic, bufferCount:Int = 0) {
		super(value, bufferType, bufferCount);

		if (Reflect.field(value, 'isStorageBufferAttribute') !== true && Reflect.field(value, 'isStorageInstancedBufferAttribute') !== true) {
			// TOOD: Improve it, possibly adding a new property to the BufferAttribute to identify it as a storage buffer read-only attribute in Renderer

			if (Reflect.field(value, 'isInstancedBufferAttribute')) Reflect.setField(value, 'isStorageInstancedBufferAttribute', true);
			else Reflect.setField(value, 'isStorageBufferAttribute', true);
		}
	}

	public function getInputType( /*builder*/ ) {
		return 'storageBuffer';
	}

	public function element(indexNode:Dynamic) {
		return storageElement(this, indexNode);
	}

	public function setBufferObject(value:Bool) {
		this.bufferObject = value;
		return this;
	}

	public function generate(builder:Dynamic) {
		if (Reflect.field(builder, 'isAvailable')('storageBuffer')) return super.generate(builder);

		const nodeType = this.getNodeType(builder);

		if (this._attribute == null) {
			this._attribute = bufferAttribute(this.value);
			this._varying = varying(this._attribute);
		}

		const output = this._varying.build(builder, nodeType);
		builder.registerTransform(output, this._attribute);

		return output;
	}
}

export default StorageBufferNode;

export function storage(value:Dynamic, type:Dynamic, count:Int) {
	return nodeObject(new StorageBufferNode(value, type, count));
}

export function storageObject(value:Dynamic, type:Dynamic, count:Int) {
	return nodeObject(new StorageBufferNode(value, type, count).setBufferObject(true));
}

addNodeClass('StorageBufferNode', StorageBufferNode);