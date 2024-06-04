import InputNode from "../core/InputNode";
import {addNodeClass} from "../core/Node";
import {varying} from "../core/VaryingNode";
import {nodeObject, addNodeElement} from "../shadernode/ShaderNode";
import {InterleavedBufferAttribute, InterleavedBuffer, StaticDrawUsage, DynamicDrawUsage} from "three";

class BufferAttributeNode extends InputNode {
	public var isBufferNode:Bool = true;
	public var bufferType:Null<String> = null;
	public var bufferStride:Int = 0;
	public var bufferOffset:Int = 0;
	public var usage:Int = StaticDrawUsage;
	public var instanced:Bool = false;
	public var attribute:Null<InterleavedBufferAttribute> = null;

	public function new(value:Dynamic, bufferType:Null<String> = null, bufferStride:Int = 0, bufferOffset:Int = 0) {
		super(value, bufferType);
		this.bufferType = bufferType;
		this.bufferStride = bufferStride;
		this.bufferOffset = bufferOffset;
		if (value != null && Reflect.hasField(value, "isBufferAttribute") && Reflect.field(value, "isBufferAttribute")) {
			this.attribute = cast value;
			this.usage = this.attribute.usage;
			this.instanced = this.attribute.isInstancedBufferAttribute;
		}
	}

	public function getNodeType(builder:Dynamic):String {
		if (this.bufferType == null) {
			this.bufferType = builder.getTypeFromAttribute(this.attribute);
		}
		return this.bufferType;
	}

	public function setup(builder:Dynamic):Void {
		if (this.attribute != null) {
			return;
		}
		var type = this.getNodeType(builder);
		var array = this.value;
		var itemSize = builder.getTypeLength(type);
		var stride = this.bufferStride != 0 ? this.bufferStride : itemSize;
		var offset = this.bufferOffset;
		var buffer = Reflect.hasField(array, "isInterleavedBuffer") && Reflect.field(array, "isInterleavedBuffer") ? array : new InterleavedBuffer(array, stride);
		var bufferAttribute = new InterleavedBufferAttribute(buffer, itemSize, offset);
		buffer.setUsage(this.usage);
		this.attribute = bufferAttribute;
		this.attribute.isInstancedBufferAttribute = this.instanced;
	}

	public function generate(builder:Dynamic):Dynamic {
		var nodeType = this.getNodeType(builder);
		var nodeAttribute = builder.getBufferAttributeFromNode(this, nodeType);
		var propertyName = builder.getPropertyName(nodeAttribute);
		var output:Dynamic = null;
		if (builder.shaderStage == "vertex" || builder.shaderStage == "compute") {
			this.name = propertyName;
			output = propertyName;
		} else {
			var nodeVarying = varying(this);
			output = nodeVarying.build(builder, nodeType);
		}
		return output;
	}

	public function getInputType(builder:Dynamic):String {
		return "bufferAttribute";
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

export var BufferAttributeNode = BufferAttributeNode;

export function bufferAttribute(array:Dynamic, type:Null<String> = null, stride:Int = 0, offset:Int = 0):Dynamic {
	return nodeObject(new BufferAttributeNode(array, type, stride, offset));
}

export function dynamicBufferAttribute(array:Dynamic, type:Null<String> = null, stride:Int = 0, offset:Int = 0):Dynamic {
	return bufferAttribute(array, type, stride, offset).setUsage(DynamicDrawUsage);
}

export function instancedBufferAttribute(array:Dynamic, type:Null<String> = null, stride:Int = 0, offset:Int = 0):Dynamic {
	return bufferAttribute(array, type, stride, offset).setInstanced(true);
}

export function instancedDynamicBufferAttribute(array:Dynamic, type:Null<String> = null, stride:Int = 0, offset:Int = 0):Dynamic {
	return dynamicBufferAttribute(array, type, stride, offset).setInstanced(true);
}

addNodeElement("toAttribute", function(bufferNode:Dynamic):Dynamic {
	return bufferAttribute(bufferNode.value);
});

addNodeClass("BufferAttributeNode", BufferAttributeNode);