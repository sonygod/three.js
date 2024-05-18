package three.js.examples.jm.nodes.accessors;

import three.js.core.Node;
import three.js.core.PropertyNode;
import three.js.nodes.BufferAttributeNode;
import three.js.nodes.NormalNode;
import three.js.nodes.PositionNode;
import three.js.shadernode.ShaderNode;

class InstanceNode extends Node {

    public var instanceMesh:Dynamic;

    public var instanceMatrixNode:Dynamic;

    public var instanceColorNode:Dynamic;

    public function new(instanceMesh:Dynamic) {
        super('void');
        this.instanceMesh = instanceMesh;
        this.instanceMatrixNode = null;
        this.instanceColorNode = null;
    }

    public function setup(?builder:Dynamic) {
        var instanceMatrixNode:Dynamic = this.instanceMatrixNode;
        var instanceMesh:Dynamic = this.instanceMesh;

        if (instanceMatrixNode === null) {
            var instanceAttribute:Dynamic = instanceMesh.instanceMatrix;
            var buffer:InstancedInterleavedBuffer = new InstancedInterleavedBuffer(instanceAttribute.array, 16, 1);
            var bufferFn:Dynamic = instanceAttribute.usage == DynamicDrawUsage ? instancedDynamicBufferAttribute : instancedBufferAttribute;
            var instanceBuffers:Array<Dynamic> = [
                bufferFn(buffer, 'vec4', 16, 0),
                bufferFn(buffer, 'vec4', 16, 4),
                bufferFn(buffer, 'vec4', 16, 8),
                bufferFn(buffer, 'vec4', 16, 12)
            ];
            instanceMatrixNode = mat4(instanceBuffers[0], instanceBuffers[1], instanceBuffers[2], instanceBuffers[3]);
            this.instanceMatrixNode = instanceMatrixNode;
        }

        var instanceColorAttribute:Dynamic = instanceMesh.instanceColor;

        if (instanceColorAttribute && this.instanceColorNode === null) {
            var buffer:InstancedBufferAttribute = new InstancedBufferAttribute(instanceColorAttribute.array, 3);
            var bufferFn:Dynamic = instanceColorAttribute.usage == DynamicDrawUsage ? instancedDynamicBufferAttribute : instancedBufferAttribute;
            this.instanceColorNode = vec3(bufferFn(buffer, 'vec3', 3, 0));
        }

        // POSITION
        var instancePosition:Dynamic = instanceMatrixNode.mul(positionLocal).xyz;

        // NORMAL
        var m:mat3 = new mat3(instanceMatrixNode[0].xyz, instanceMatrixNode[1].xyz, instanceMatrixNode[2].xyz);
        var transformedNormal:Dynamic = normalLocal.div(vec3(m[0].dot(m[0]), m[1].dot(m[1]), m[2].dot(m[2])));
        var instanceNormal:Dynamic = m.mul(transformedNormal).xyz;

        // ASSIGNS
        positionLocal.assign(instancePosition);
        normalLocal.assign(instanceNormal);

        // COLOR
        if (this.instanceColorNode !== null) {
            varyingProperty('vec3', 'vInstanceColor').assign(this.instanceColorNode);
        }
    }
}

typedef InstancedInterleavedBuffer = {
    array:Dynamic,
    stride:Int,
    itemSize:Int
}

typedef InstancedBufferAttribute = {
    array:Dynamic,
    itemSize:Int
}

extern class InstancedInterleavedBuffer {
    public function new(array:Dynamic, stride:Int, itemSize:Int);
}

extern class InstancedBufferAttribute {
    public function new(array:Dynamic, itemSize:Int);
}

extern class mat3 {
    public function new(a:Dynamic, b:Dynamic, c:Dynamic);
    public function dot(v:Dynamic):Dynamic;
    public function mul(v:Dynamic):Dynamic;
}

extern class mat4 {
    public function new(a:Dynamic, b:Dynamic, c:Dynamic, d:Dynamic);
    public function mul(v:Dynamic):Dynamic;
}

extern class vec3 {
    public function new(x:Float, y:Float, z:Float);
    public function dot(v:vec3):Float;
    public function assign(v:vec3):void;
}

extern class ShaderNode {
    public static function nodeProxy<T>(nodeClass:Class<T>):T;
}

extern class PropertyNode {
    public static function varyingProperty(type:String, name:String):Dynamic;
}

extern class BufferAttributeNode {
    public static function instancedBufferAttribute(buffer:InstancedBufferAttribute, type:String, stride:Int, offset:Int):Dynamic;
    public static function instancedDynamicBufferAttribute(buffer:InstancedBufferAttribute, type:String, stride:Int, offset:Int):Dynamic;
}

extern class NormalNode {
    public static var normalLocal:Dynamic;
}

extern class PositionNode {
    public static var positionLocal:Dynamic;
}

ShaderNode.nodeProxy(InstanceNode);

Node.addNodeClass('InstanceNode', InstanceNode);