import InputNode from '../core/InputNode.js';
import { addNodeClass } from '../core/Node.js';
import { varying } from '../core/VaryingNode.js';
import { nodeObject, addNodeElement } from '../shadernode/ShaderNode.js';
import { InterleavedBufferAttribute, InterleavedBuffer, StaticDrawUsage, DynamicDrawUsage } from 'three';

class BufferAttributeNode extends InputNode {

	public var isBufferNode:Bool;
	public var bufferType:Null<Dynamic>;
	public var bufferStride:Int;
	public var bufferOffset:Int;
	public var usage:Dynamic;
	public var instanced:Bool;
	public var attribute:Null<InterleavedBufferAttribute>;

	public function new(value:Dynamic, bufferType:Null<Dynamic> = null, bufferStride:Int = 0, bufferOffset:Int = 0) {
		super(value, bufferType);

		this.isBufferNode = true;

		this.bufferType = bufferType;
		this.bufferStride = bufferStride;
		this.bufferOffset = bufferOffset;

		this.usage = StaticDrawUsage;
		this.instanced = false;

		this.attribute = null;

		if (Std.is(value, InterleavedBufferAttribute) && value.isBufferAttribute) {
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

		var type:Dynamic = this.getNodeType(builder);
		var array:Dynamic = this.value;
		var itemSize:Int = builder.getTypeLength(type);
		var stride:Int = this.bufferStride || itemSize;
		var offset:Int = this.bufferOffset;

		var buffer:Dynamic = Std.is(array, InterleavedBuffer) ? array : new InterleavedBuffer(array, stride);
		var bufferAttribute:InterleavedBufferAttribute = new InterleavedBufferAttribute(buffer, itemSize, offset);

		buffer.setUsage(this.usage);

		this.attribute = bufferAttribute;
		this.attribute.isInstancedBufferAttribute = this.instanced;
	}

	public function generate(builder:Dynamic):Dynamic {
		var nodeType:Dynamic = this.getNodeType(builder);

		var nodeAttribute:Dynamic = builder.getBufferAttributeFromNode(this, nodeType);
		var propertyName:String = builder.getPropertyName(nodeAttribute);

		var output:Dynamic = null;

		if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
			this.name = propertyName;

			output = propertyName;
		} else {
			var nodeVarying:Dynamic = varying(this);

			output = nodeVarying.build(builder, nodeType);
		}

		return output;
	}

	public function getInputType(/*builder:Dynamic*/):String {
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

export default BufferAttributeNode;

export function bufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):Dynamic {
	return nodeObject(new BufferAttributeNode(array, type, stride, offset));
}

export function dynamicBufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):Dynamic {
	return bufferAttribute(array, type, stride, offset).setUsage(DynamicDrawUsage);
}

export function instancedBufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):Dynamic {
	return bufferAttribute(array, type, stride, offset).setInstanced(true);
}

export function instancedDynamicBufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):Dynamic {
	return dynamicBufferAttribute(array, type, stride, offset).setInstanced(true);
}

addNodeElement('toAttribute', (bufferNode:Dynamic) -> bufferAttribute(bufferNode.value));

addNodeClass('BufferAttributeNode', BufferAttributeNode);