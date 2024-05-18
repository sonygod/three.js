package three.js.examples.jvm.nodes.geometry;

import three.js.core.Node;
import three.js.core.NodeUtils;
import three.js.accessors.BufferNode;
import three.js.accessors.IndexNode;
import three.js.shadernode.ShaderNode;
import three.js.THREE;

class RangeNode extends Node {

    public var minNode:ShaderNode;
    public var maxNode:ShaderNode;

    public function new(?minNode:ShaderNode = null, ?maxNode:ShaderNode = null) {
        super();
        this.minNode = minNode != null ? minNode : new ShaderNode(ShaderNode.FLOAT);
        this.maxNode = maxNode != null ? maxNode : new ShaderNode(ShaderNode.FLOAT);
    }

    public function getVectorLength(builder:Dynamic):Int {
        var minLength:Int = builder.getTypeLength(NodeUtils.getValueType(minNode.value));
        var maxLength:Int = builder.getTypeLength(NodeUtils.getValueType(maxNode.value));
        return minLength > maxLength ? minLength : maxLength;
    }

    public function getNodeType(builder:Dynamic):String {
        return builder.object.isInstancedMesh ? builder.getTypeFromLength(getVectorLength(builder)) : 'float';
    }

    public function setup(builder:Dynamic):ShaderNode {
        var object:Dynamic = builder.object;
        var output:ShaderNode = null;

        if (object.isInstancedMesh) {
            var minValue:Dynamic = minNode.value;
            var maxValue:Dynamic = maxNode.value;

            var minLength:Int = builder.getTypeLength(NodeUtils.getValueType(minValue));
            var maxLength:Int = builder.getTypeLength(NodeUtils.getValueType(maxValue));

            if (min == null) min = new THREE.Vector4();
            if (max == null) max = new THREE.Vector4();

            min.setScalar(0);
            max.setScalar(0);

            if (minLength == 1) min.setScalar(minValue);
            else if (minValue.isColor) min.set(minValue.r, minValue.g, minValue.b);
            else min.set(minValue.x, minValue.y, minValue.z || 0, minValue.w || 0);

            if (maxLength == 1) max.setScalar(maxValue);
            else if (maxValue.isColor) max.set(maxValue.r, maxValue.g, maxValue.b);
            else max.set(maxValue.x, maxValue.y, maxValue.z || 0, maxValue.w || 0);

            var stride:Int = 4;
            var length:Int = stride * object.count;
            var array:Float32Array = new Float32Array(length);

            for (i in 0...length) {
                var index:Int = i % stride;
                var minElementValue:Float = min.getComponent(index);
                var maxElementValue:Float = max.getComponent(index);
                array[i] = THREE.MathUtils.lerp(minElementValue, maxElementValue, Math.random());
            }

            var nodeType:String = getNodeType(builder);
            output = BufferNode.buffer(array, 'vec4', object.count).element(IndexNode.instanceIndex).convert(nodeType);
            //output = BufferAttributeNode.bufferAttribute(array, 'vec4', 4, 0).convert(nodeType);
        } else {
            output = new ShaderNode(ShaderNode.FLOAT, 0);
        }

        return output;
    }
}

// Export the class
export RangeNode;

// Create a proxy for the class
var range:ShaderNode = ShaderNode.nodeProxy(RangeNode);

// Add the class to the node registry
Node.addNodeClass('RangeNode', RangeNode);