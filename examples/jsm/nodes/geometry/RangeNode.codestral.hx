import Node from '../core/Node.hx';
import NodeUtils from '../core/NodeUtils.hx';
import BufferNode from '../accessors/BufferNode.hx';
import IndexNode from '../core/IndexNode.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

import three.Vector4 from 'three';
import three.MathUtils from 'three';

class RangeNode extends Node {

    public var minNode:ShaderNode.Node;
    public var maxNode:ShaderNode.Node;

    private var min:Vector4;
    private var max:Vector4;

    public function new(minNode:ShaderNode.Node = null, maxNode:ShaderNode.Node = null) {
        if (minNode == null) minNode = ShaderNode.float();
        if (maxNode == null) maxNode = ShaderNode.float();

        super();

        this.minNode = minNode;
        this.maxNode = maxNode;

        this.min = new Vector4();
        this.max = new Vector4();
    }

    public function getVectorLength(builder:any):Int {
        var minLength:Int = builder.getTypeLength(NodeUtils.getValueType(this.minNode.value));
        var maxLength:Int = builder.getTypeLength(NodeUtils.getValueType(this.maxNode.value));

        return minLength > maxLength ? minLength : maxLength;
    }

    public function getNodeType(builder:any):String {
        return builder.object.isInstancedMesh ? builder.getTypeFromLength(this.getVectorLength(builder)) : 'float';
    }

    public function setup(builder:any):ShaderNode.Node {
        var object = builder.object;

        var output:ShaderNode.Node = null;

        if (object.isInstancedMesh) {
            var minValue = this.minNode.value;
            var maxValue = this.maxNode.value;

            var minLength:Int = builder.getTypeLength(NodeUtils.getValueType(minValue));
            var maxLength:Int = builder.getTypeLength(NodeUtils.getValueType(maxValue));

            this.min.setScalar(0);
            this.max.setScalar(0);

            if (minLength == 1) this.min.setScalar(minValue);
            else if (Std.is(minValue, three.Color)) this.min.set(minValue.r, minValue.g, minValue.b);
            else this.min.set(minValue.x, minValue.y, minValue.z == null ? 0 : minValue.z, minValue.w == null ? 0 : minValue.w);

            if (maxLength == 1) this.max.setScalar(maxValue);
            else if (Std.is(maxValue, three.Color)) this.max.set(maxValue.r, maxValue.g, maxValue.b);
            else this.max.set(maxValue.x, maxValue.y, maxValue.z == null ? 0 : maxValue.z, maxValue.w == null ? 0 : maxValue.w);

            var stride:Int = 4;

            var length:Int = stride * object.count;
            var array:Float32Array = new Float32Array(length);

            for (var i:Int = 0; i < length; i++) {
                var index:Int = i % stride;

                var minElementValue:Float = this.min.getComponent(index);
                var maxElementValue:Float = this.max.getComponent(index);

                array[i] = MathUtils.lerp(minElementValue, maxElementValue, Math.random());
            }

            var nodeType:String = this.getNodeType(builder);

            output = BufferNode.buffer(array, 'vec4', object.count).element(IndexNode.instanceIndex).convert(nodeType);
        } else {
            output = ShaderNode.float(0);
        }

        return output;
    }
}

class RangeNodeProxy extends ShaderNode.NodeProxy {
    public function new() {
        super(RangeNode);
    }
}

Node.addNodeClass('RangeNode', RangeNode);

export default RangeNode;
export var range = new RangeNodeProxy();