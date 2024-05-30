package three.js.examples.jvm.nodes.accessors;

import three.js.core.Node;
import three.js.core.PropertyNode;
import three.js.nodes.BufferAttributeNode;
import three.js.nodes.NormalNode;
import three.js.nodes.PositionNode;
import three.js.shadernode.ShaderNode;
import three.DynamicDrawUsage;
import three.InstancedInterleavedBuffer;
import three.InstancedBufferAttribute;

class InstanceNode extends Node {

    var instanceMesh:Dynamic;
    var instanceMatrixNode:ShaderNode;
    var instanceColorNode:ShaderNode;

    public function new(instanceMesh:Dynamic) {
        super('void');
        this.instanceMesh = instanceMesh;
        this.instanceMatrixNode = null;
        this.instanceColorNode = null;
    }

    public function setup(builder:Dynamic) {
        var instanceMatrixNode:ShaderNode = this.instanceMatrixNode;
        var instanceMesh:Dynamic = this.instanceMesh;

        if (instanceMatrixNode == null) {
            var instanceAttribute:Dynamic = instanceMesh.instanceMatrix;
            var buffer:InstancedInterleavedBuffer = new InstancedInterleavedBuffer(instanceAttribute.array, 16, 1);

            var bufferFn:Dynamic = instanceAttribute.usage == DynamicDrawUsage ? BufferAttributeNode.instancedDynamicBufferAttribute : BufferAttributeNode.instancedBufferAttribute;

            var instanceBuffers:Array<ShaderNode> = [
                bufferFn(buffer, 'vec4', 16, 0),
                bufferFn(buffer, 'vec4', 16, 4),
                bufferFn(buffer, 'vec4', 16, 8),
                bufferFn(buffer, 'vec4', 16, 12)
            ];

            instanceMatrixNode = ShaderNode.mat4(instanceBuffers[0], instanceBuffers[1], instanceBuffers[2], instanceBuffers[3]);

            this.instanceMatrixNode = instanceMatrixNode;
        }

        var instanceColorAttribute:Dynamic = instanceMesh.instanceColor;

        if (instanceColorAttribute && this.instanceColorNode == null) {
            var buffer:InstancedBufferAttribute = new InstancedBufferAttribute(instanceColorAttribute.array, 3);
            var bufferFn:Dynamic = instanceColorAttribute.usage == DynamicDrawUsage ? BufferAttributeNode.instancedDynamicBufferAttribute : BufferAttributeNode.instancedBufferAttribute;

            this.instanceColorNode = ShaderNode.vec3(bufferFn(buffer, 'vec3', 3, 0));
        }

        // POSITION

        var instancePosition = ShaderNode.mul(instanceMatrixNode, PositionNode.local).xyz;

        // NORMAL

        var m:ShaderNode = ShaderNode.mat3(instanceMatrixNode[0].xyz, instanceMatrixNode[1].xyz, instanceMatrixNode[2].xyz);

        var transformedNormal = ShaderNode.div(NormalNode.local, ShaderNode.vec3(m[0].dot(m[0]), m[1].dot(m[1]), m[2].dot(m[2])));

        var instanceNormal = ShaderNode.mul(m, transformedNormal).xyz;

        // ASSIGNS

        PositionNode.local.assign(instancePosition);
        NormalNode.local.assign(instanceNormal);

        // COLOR

        if (this.instanceColorNode != null) {
            PropertyNode.varyingProperty('vec3', 'vInstanceColor').assign(this.instanceColorNode);
        }
    }
}

#if js
extern class InstanceNode extends Node {
    public function new(instanceMesh:Dynamic);
    public function setup(builder:Dynamic);
}
#else
extern class InstanceNode {
    public function new(instanceMesh:Dynamic);
    public function setup(builder:Dynamic);
}
#end

@:keep
@:bindABLE
extern class InstanceNode {
    public function new(instanceMesh:Dynamic);
    public function setup(builder:Dynamic);
}

@:native('instance')
extern class InstanceNodeProxy {}

 ShaderNode.addNodeClass('InstanceNode', InstanceNode);