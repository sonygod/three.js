package three.js.examples.jvm.nodes.geometry;

import three.js.core.Node;
import three.js.core.NodeUtils;
import three.js.accessors.BufferNode;
import three.js.core.IndexNode;
import three.js.shadernode.ShaderNode;
import three.math.Vector4;
import three.math.MathUtils;

class RangeNode extends Node {

    public var minNode:ShaderNode;
    public var maxNode:ShaderNode;

    public function new(minNode:ShaderNode = new ShaderNode(ShaderNode.Float), maxNode:ShaderNode = new ShaderNode(ShaderNode.Float)) {
        super();
        this.minNode = minNode;
        this.maxNode = maxNode;
    }

    private function getVectorLength(builder:Dynamic):Int {
        var minLength:Int = builder.getTypeLength(NodeUtils.getValueType(minNode.value));
        var maxLength:Int = builder.getTypeLength(NodeUtils.getValueType(maxNode.value));
        return Math.max(minLength, maxLength);
    }

    private function getNodeType(builder:Dynamic):String {
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

            var min:Vector4 = min == null ? new Vector4() : min;
            var max:Vector4 = max == null ? new Vector4() : max;

            min.setScalar(0);
            max.setScalar(0);

            if (minLength == 1) min.setScalar(minValue);
            else if (Std.isOfType(minValue, Color)) min.set(minValue.r, minValue.g, minValue.b);
            else min.set(minValue.x, minValue.y, minValue.z == null ? 0 : minValue.z, minValue.w == null ? 0 : minValue.w);

            if (maxLength == 1) max.setScalar(maxValue);
            else if (Std.isOfType(maxValue, Color)) max.set(maxValue.r, maxValue.g, maxValue.b);
            else max.set(maxValue.x, maxValue.y, maxValue.z == null ? 0 : maxValue.z, maxValue.w == null ? 0 : maxValue.w);

            var stride:Int = 4;
            var length:Int = stride * object.count;
            var array:Float32Array = new Float32Array(length);

            for (i in 0...length) {
                var index:Int = i % stride;
                var minElementValue:Float = min.getComponent(index);
                var maxElementValue:Float = max.getComponent(index);
                array[i] = MathUtils.lerp(minElementValue, maxElementValue, Math.random());
            }

            var nodeType:String = getNodeType(builder);
            output = BufferNode.buffer(array, 'vec4', object.count).element(IndexNode.instanceIndex).convert(nodeType);
            //output = BufferAttributeNode.bufferAttribute(array, 'vec4', 4, 0).convert(nodeType);
        } else {
            output = ShaderNode.float(0);
        }

        return output;
    }

    static var min:Vector4;
    static var max:Vector4;

}

@:keep
class RangeNodeProxy extends ShaderNodeProxy<RangeNode> {
    public function new() super(new RangeNode());
}

@:keep
class RangeNodeTools {
    public static function range(min:ShaderNode = new ShaderNode(ShaderNode.Float), max:ShaderNode = new ShaderNode(ShaderNode.Float)) {
        return new RangeNodeProxy().node;
    }
}

Node.addClass('RangeNode', RangeNode);