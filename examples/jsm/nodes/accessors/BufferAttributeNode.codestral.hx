import InputNode from '../core/InputNode';
import Node from '../core/Node';
import VaryingNode from '../core/VaryingNode';
import ShaderNode from '../shadernode/ShaderNode';
import { InterleavedBufferAttribute, InterleavedBuffer, StaticDrawUsage, DynamicDrawUsage } from 'three';

class BufferAttributeNode extends InputNode {

	public var bufferType:Dynamic;
	public var bufferStride:Int;
	public var bufferOffset:Int;
	public var usage:Int;
	public var instanced:Bool;
	public var attribute:Dynamic;

	public function new(value:Dynamic, bufferType:Dynamic = null, bufferStride:Int = 0, bufferOffset:Int = 0) {
		super(value, bufferType);

		this.isBufferNode = true;

		this.bufferType = bufferType;
		this.bufferStride = bufferStride;
		this.bufferOffset = bufferOffset;

		this.usage = StaticDrawUsage;
		this.instanced = false;

		this.attribute = null;

		if (value != null && Reflect.hasField(value, 'isBufferAttribute') && value.isBufferAttribute === true) {
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

		const type:Dynamic = this.getNodeType(builder);
		const array:Dynamic = this.value;
		const itemSize:Int = builder.getTypeLength(type);
		const stride:Int = this.bufferStride != 0 ? this.bufferStride : itemSize;
		const offset:Int = this.bufferOffset;

		const buffer:Dynamic = Reflect.hasField(array, 'isInterleavedBuffer') && array.isInterleavedBuffer === true ? array : new InterleavedBuffer(array, stride);
		const bufferAttribute:Dynamic = new InterleavedBufferAttribute(buffer, itemSize, offset);

		buffer.setUsage(this.usage);

		this.attribute = bufferAttribute;
		this.attribute.isInstancedBufferAttribute = this.instanced;
	}

	public function generate(builder:Dynamic):Dynamic {
		const nodeType:Dynamic = this.getNodeType(builder);

		const nodeAttribute:Dynamic = builder.getBufferAttributeFromNode(this, nodeType);
		const propertyName:String = builder.getPropertyName(nodeAttribute);

		let output:Dynamic = null;

		if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
			this.name = propertyName;
			output = propertyName;
		} else {
			const nodeVarying:VaryingNode = new VaryingNode(this);
			output = nodeVarying.build(builder, nodeType);
		}

		return output;
	}

	public function getInputType(/*builder*/):String {
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

export function bufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):ShaderNode {
	return ShaderNode.nodeObject(new BufferAttributeNode(array, type, stride, offset));
}

export function dynamicBufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):ShaderNode {
	return bufferAttribute(array, type, stride, offset).setUsage(DynamicDrawUsage);
}

export function instancedBufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):ShaderNode {
	return bufferAttribute(array, type, stride, offset).setInstanced(true);
}

export function instancedDynamicBufferAttribute(array:Dynamic, type:Dynamic, stride:Int, offset:Int):ShaderNode {
	return dynamicBufferAttribute(array, type, stride, offset).setInstanced(true);
}

ShaderNode.addNodeElement('toAttribute', (bufferNode:BufferAttributeNode) => bufferAttribute(bufferNode.value));

Node.addNodeClass('BufferAttributeNode', BufferAttributeNode);