import three.Node;
import three.core.PropertyNode.varyingProperty;
import three.nodes.BufferAttributeNode.instancedBufferAttribute;
import three.nodes.BufferAttributeNode.instancedDynamicBufferAttribute;
import three.nodes.NormalNode.normalLocal;
import three.nodes.PositionNode.positionLocal;
import three.shadernode.ShaderNode.nodeProxy;
import three.shadernode.ShaderNode.vec3;
import three.shadernode.ShaderNode.mat3;
import three.shadernode.ShaderNode.mat4;
import three.three.DynamicDrawUsage;
import three.three.InstancedInterleavedBuffer;
import three.three.InstancedBufferAttribute;

class InstanceNode extends Node {

	public function new(instanceMesh:Dynamic) {
		super('void');

		this.instanceMesh = instanceMesh;
		this.instanceMatrixNode = null;
		this.instanceColorNode = null;
	}

	public function setup() {
		var instanceMatrixNode = this.instanceMatrixNode;
		var instanceMesh = this.instanceMesh;

		if (instanceMatrixNode == null) {
			var instanceAttribute = instanceMesh.instanceMatrix;
			var buffer = new InstancedInterleavedBuffer(instanceAttribute.array, 16, 1);

			var bufferFn = instanceAttribute.usage == DynamicDrawUsage ? instancedDynamicBufferAttribute : instancedBufferAttribute;

			var instanceBuffers = [
				bufferFn(buffer, 'vec4', 16, 0),
				bufferFn(buffer, 'vec4', 16, 4),
				bufferFn(buffer, 'vec4', 16, 8),
				bufferFn(buffer, 'vec4', 16, 12)
			];

			instanceMatrixNode = mat4(instanceBuffers);
			this.instanceMatrixNode = instanceMatrixNode;
		}

		var instanceColorAttribute = instanceMesh.instanceColor;

		if (instanceColorAttribute && this.instanceColorNode == null) {
			var buffer = new InstancedBufferAttribute(instanceColorAttribute.array, 3);
			var bufferFn = instanceColorAttribute.usage == DynamicDrawUsage ? instancedDynamicBufferAttribute : instancedBufferAttribute;

			this.instanceColorNode = vec3(bufferFn(buffer, 'vec3', 3, 0));
		}

		var instancePosition = instanceMatrixNode.mul(positionLocal).xyz;

		var m = mat3(instanceMatrixNode[0].xyz, instanceMatrixNode[1].xyz, instanceMatrixNode[2].xyz);

		var transformedNormal = normalLocal.div(vec3(m[0].dot(m[0]), m[1].dot(m[1]), m[2].dot(m[2])));

		var instanceNormal = m.mul(transformedNormal).xyz;

		positionLocal.assign(instancePosition);
		normalLocal.assign(instanceNormal);

		if (this.instanceColorNode != null) {
			varyingProperty('vec3', 'vInstanceColor').assign(this.instanceColorNode);
		}
	}
}

static var instance = nodeProxy(InstanceNode);

Node.addNodeClass('InstanceNode', InstanceNode);