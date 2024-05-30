import BufferNode from './BufferNode.js';
import { bufferAttribute } from './BufferAttributeNode.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';
import { varying } from '../core/VaryingNode.js';
import { storageElement } from '../utils/StorageArrayElementNode.js';

class StorageBufferNode extends BufferNode {

	public function new(value, bufferType, bufferCount = 0) {

		super(value, bufferType, bufferCount);

		this.isStorageBufferNode = true;

		this.bufferObject = false;

		this._attribute = null;
		this._varying = null;

		if (value.isStorageBufferAttribute !== true && value.isStorageInstancedBufferAttribute !== true) {

			// TOOD: Improve it, possibly adding a new property to the BufferAttribute to identify it as a storage buffer read-only attribute in Renderer

			if (value.isInstancedBufferAttribute) value.isStorageInstancedBufferAttribute = true;
			else value.isStorageBufferAttribute = true;

		}

	}

	public function getInputType(/*builder*/) {

		return 'storageBuffer';

	}

	public function element(indexNode) {

		return storageElement(this, indexNode);

	}

	public function setBufferObject(value) {

		this.bufferObject = value;

		return this;

	}

	public function generate(builder) {

		if (builder.isAvailable('storageBuffer')) return super.generate(builder);

		var nodeType = this.getNodeType(builder);

		if (this._attribute === null) {

			this._attribute = bufferAttribute(this.value);
			this._varying = varying(this._attribute);

		}


		var output = this._varying.build(builder, nodeType);

		builder.registerTransform(output, this._attribute);

		return output;

	}

}

static function storage(value, type, count) {
	return nodeObject(new StorageBufferNode(value, type, count));
}

static function storageObject(value, type, count) {
	return nodeObject(new StorageBufferNode(value, type, count).setBufferObject(true));
}

addNodeClass('StorageBufferNode', StorageBufferNode);