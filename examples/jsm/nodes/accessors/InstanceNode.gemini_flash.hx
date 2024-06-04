import Node from "../core/Node";
import { varyingProperty } from "../core/PropertyNode";
import { instancedBufferAttribute, instancedDynamicBufferAttribute } from "./BufferAttributeNode";
import { normalLocal } from "./NormalNode";
import { positionLocal } from "./PositionNode";
import { nodeProxy, vec3, mat3, mat4 } from "../shadernode/ShaderNode";
import { DynamicDrawUsage, InstancedInterleavedBuffer, InstancedBufferAttribute } from "three";

class InstanceNode extends Node {
	public instanceMesh:Dynamic;
	public instanceMatrixNode:Dynamic;
	public instanceColorNode:Dynamic;

	public function new(instanceMesh:Dynamic) {
		super("void");
		this.instanceMesh = instanceMesh;
		this.instanceMatrixNode = null;
		this.instanceColorNode = null;
	}

	public function setup(builder:Dynamic):Void {
		var instanceMatrixNode = this.instanceMatrixNode;
		var instanceMesh = this.instanceMesh;

		if (instanceMatrixNode == null) {
			var instanceAttribute = instanceMesh.instanceMatrix;
			var buffer = new InstancedInterleavedBuffer(instanceAttribute.array, 16, 1);
			var bufferFn = instanceAttribute.usage == DynamicDrawUsage ? instancedDynamicBufferAttribute : instancedBufferAttribute;
			var instanceBuffers = [
				bufferFn(buffer, "vec4", 16, 0),
				bufferFn(buffer, "vec4", 16, 4),
				bufferFn(buffer, "vec4", 16, 8),
				bufferFn(buffer, "vec4", 16, 12)
			];
			instanceMatrixNode = mat4(instanceBuffers[0], instanceBuffers[1], instanceBuffers[2], instanceBuffers[3]);
			this.instanceMatrixNode = instanceMatrixNode;
		}

		var instanceColorAttribute = instanceMesh.instanceColor;

		if (instanceColorAttribute != null && this.instanceColorNode == null) {
			var buffer = new InstancedBufferAttribute(instanceColorAttribute.array, 3);
			var bufferFn = instanceColorAttribute.usage == DynamicDrawUsage ? instancedDynamicBufferAttribute : instancedBufferAttribute;
			this.instanceColorNode = vec3(bufferFn(buffer, "vec3", 3, 0));
		}

		// POSITION
		var instancePosition = instanceMatrixNode.mul(positionLocal).xyz;

		// NORMAL
		var m = mat3(instanceMatrixNode[0].xyz, instanceMatrixNode[1].xyz, instanceMatrixNode[2].xyz);
		var transformedNormal = normalLocal.div(vec3(m[0].dot(m[0]), m[1].dot(m[1]), m[2].dot(m[2])));
		var instanceNormal = m.mul(transformedNormal).xyz;

		// ASSIGNS
		positionLocal.assign(instancePosition);
		normalLocal.assign(instanceNormal);

		// COLOR
		if (this.instanceColorNode != null) {
			varyingProperty("vec3", "vInstanceColor").assign(this.instanceColorNode);
		}
	}
}

export var instance = nodeProxy(InstanceNode);

export default InstanceNode;