import InputNode from '../core/InputNode.js';
import { addNodeClass } from '../core/Node.js';
import { varying } from '../core/VaryingNode.js';
import { nodeObject, addNodeElement } from '../shadernode/ShaderNode.js';
import { InterleavedBufferAttribute, InterleavedBuffer, StaticDrawUsage, DynamicDrawUsage } from 'three';

class BufferAttributeNode extends InputNode {

	public function new(value, bufferType = null, bufferStride = 0, bufferOffset = 0) {

		super(value, bufferType);

		this.isBufferNode = true;

		this.bufferType = bufferType;
		this.bufferStride = bufferStride;
		this.bufferOffset = bufferOffset;

		this.usage = StaticDrawUsage;
		this.instanced = false;

		this.attribute = null;

		if (value && value.isBufferAttribute === true) {

			this.attribute = value;
			this.usage = value.usage;
			this.instanced = value.isInstancedBufferAttribute;

		}

	}

	public function getNodeType(builder) {

		if (this.bufferType === null) {

			this.bufferType = builder.getTypeFromAttribute(this.attribute);

		}

		return this.bufferType;

	}

	public function setup(builder) {

		if (this.attribute !== null) return;

		var type = this.getNodeType(builder);
		var array = this.value;
		var itemSize = builder.getTypeLength(type);
		var stride = this.bufferStride || itemSize;
		var offset = this.bufferOffset;

		var buffer = array.isInterleavedBuffer === true ? array : new InterleavedBuffer(array, stride);
		var bufferAttribute = new InterleavedBufferAttribute(buffer, itemSize, offset);

		buffer.setUsage(this.usage);

		this.attribute = bufferAttribute;
		this.attribute.isInstancedBufferAttribute = this.instanced; // @TODO: Add a possible: InstancedInterleavedBufferAttribute

	}

	public function generate(builder) {

		var nodeType = this.getNodeType(builder);

		var nodeAttribute = builder.getBufferAttributeFromNode(this, nodeType);
		var propertyName = builder.getPropertyName(nodeAttribute);

		var output = null;

		if (builder.shaderStage === 'vertex' || builder.shaderStage === 'compute') {

			this.name = propertyName;

			output = propertyName;

		} else {

			var nodeVarying = varying(this);

			output = nodeVarying.build(builder, nodeType);

		}

		return output;

	}

	public function getInputType(/*builder*/) {

		return 'bufferAttribute';

	}

	public function setUsage(value) {

		this.usage = value;

		return this;

	}

	public function setInstanced(value) {

		this.instanced = value;

		return this;

	}

}

static function bufferAttribute(array, type, stride, offset) {
	return nodeObject(new BufferAttributeNode(array, type, stride, offset));
}

static function dynamicBufferAttribute(array, type, stride, offset) {
	return bufferAttribute(array, type, stride, offset).setUsage(DynamicDrawUsage);
}

static function instancedBufferAttribute(array, type, stride, offset) {
	return bufferAttribute(array, type, stride, offset).setInstanced(true);
}

static function instancedDynamicBufferAttribute(array, type, stride, offset) {
	return dynamicBufferAttribute(array, type, stride, offset).setInstanced(true);
}

addNodeElement('toAttribute', (bufferNode) -> bufferAttribute(bufferNode.value));

addNodeClass('BufferAttributeNode', BufferAttributeNode);