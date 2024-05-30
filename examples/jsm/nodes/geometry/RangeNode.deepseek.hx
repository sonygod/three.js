package three.js.examples.jsm.nodes.geometry;

import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.NodeUtils;
import three.js.examples.jsm.nodes.accessors.BufferNode;
import three.js.examples.jsm.nodes.core.IndexNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

import three.Vector4;
import three.MathUtils;

class RangeNode extends Node {

	var minNode:ShaderNode;
	var maxNode:ShaderNode;

	public function new(minNode:ShaderNode = ShaderNode.float(), maxNode:ShaderNode = ShaderNode.float()) {
		super();
		this.minNode = minNode;
		this.maxNode = maxNode;
	}

	public function getVectorLength(builder:ShaderNode.Builder):Int {
		var minLength = builder.getTypeLength(NodeUtils.getValueType(this.minNode.value));
		var maxLength = builder.getTypeLength(NodeUtils.getValueType(this.maxNode.value));
		return minLength > maxLength ? minLength : maxLength;
	}

	public function getNodeType(builder:ShaderNode.Builder):String {
		return builder.object.isInstancedMesh ? builder.getTypeFromLength(this.getVectorLength(builder)) : 'float';
	}

	public function setup(builder:ShaderNode.Builder):ShaderNode {
		var object = builder.object;
		var output:ShaderNode = null;
		if (object.isInstancedMesh) {
			var minValue = this.minNode.value;
			var maxValue = this.maxNode.value;
			var minLength = builder.getTypeLength(NodeUtils.getValueType(minValue));
			var maxLength = builder.getTypeLength(NodeUtils.getValueType(maxValue));
			var min = new Vector4();
			var max = new Vector4();
			min.setScalar(0);
			max.setScalar(0);
			if (minLength == 1) min.setScalar(Std.parseFloat(minValue));
			else if (minValue.isColor) min.set(minValue.r, minValue.g, minValue.b);
			else min.set(minValue.x, minValue.y, minValue.z || 0, minValue.w || 0);
			if (maxLength == 1) max.setScalar(Std.parseFloat(maxValue));
			else if (maxValue.isColor) max.set(maxValue.r, maxValue.g, maxValue.b);
			else max.set(maxValue.x, maxValue.y, maxValue.z || 0, maxValue.w || 0);
			var stride = 4;
			var length = stride * object.count;
			var array = new Float32Array(length);
			for (i in 0...length) {
				var index = i % stride;
				var minElementValue = min.getComponent(index);
				var maxElementValue = max.getComponent(index);
				array[i] = MathUtils.lerp(minElementValue, maxElementValue, Math.random());
			}
			var nodeType = this.getNodeType(builder);
			output = BufferNode.buffer(array, 'vec4', object.count).element(IndexNode.instanceIndex).convert(nodeType);
		} else {
			output = ShaderNode.float(0);
		}
		return output;
	}

}

class RangeNodeProxy extends ShaderNode {
	public function new() {
		super();
	}
}

Node.addNodeClass('RangeNode', RangeNode);