import Node from '../core/Node.hx';
import { getValueType } from '../core/NodeUtils.hx';
import { buffer } from '../accessors/BufferNode.hx';
import { instanceIndex } from '../core/IndexNode.hx';
import { nodeProxy, float } from '../shadernode/ShaderNode.hx';

import Vector4 from 'three/src/math/Vector4.hx';
import MathUtils from 'three/src/math/MathUtils.hx';

class RangeNode extends Node {
    var minNode: Dynamic;
    var maxNode: Dynamic;

    public function new(minNode: Dynamic = float(), maxNode: Dynamic = float()) {
        super();
        this.minNode = minNode;
        this.maxNode = maxNode;
    }

    function getVectorLength(builder: Dynamic) {
        var minLength = builder.getTypeLength(getValueType(this.minNode.value));
        var maxLength = builder.getTypeLength(getValueType(this.maxNode.value));
        return minLength > maxLength ? minLength : maxLength;
    }

    function getNodeType(builder: Dynamic) {
        var object = builder.object;
        if (object.isInstancedMesh) {
            return builder.getTypeFromLength(this.getVectorLength(builder));
        } else {
            return 'float';
        }
    }

    function setup(builder: Dynamic) {
        var object = builder.object;
        var output: Dynamic;
        if (object.isInstancedMesh) {
            var minValue = this.minNode.value;
            var maxValue = this.maxNode.value;
            var minLength = builder.getTypeLength(getValueType(minValue));
            var maxLength = builder.getTypeLength(getValueType(maxValue));
            var min = Vector4._new(0.0, 0.0, 0.0, 0.0);
            var max = Vector4._new(0.0, 0.0, 0.0, 0.0);
            if (minLength == 1) {
                min.setScalar(minValue);
            } else if (Reflect.hasField(minValue, 'isColor') && minValue.isColor) {
                min.set(minValue.r, minValue.g, minValue.b, 0.0);
            } else {
                min.set(minValue.x, minValue.y, minValue.z ?? 0.0, minValue.w ?? 0.0);
            }
            if (maxLength == 1) {
                max.setScalar(maxValue);
            } else if (Reflect.hasField(maxValue, 'isColor') && maxValue.isColor) {
                max.set(maxValue.r, maxValue.g, maxValue.b, 0.0);
            } else {
                max.set(maxValue.x, maxValue.y, maxValue.z ?? 0.0, maxValue.w ?? 0.0);
            }
            var stride = 4;
            var length = stride * object.count;
            var array = Float32Array._new(length);
            var i = 0;
            while (i < length) {
                var index = i % stride;
                var minElementValue = min.getComponent(index);
                var maxElementValue = max.getComponent(index);
                array[i] = MathUtils.lerp(minElementValue, maxElementValue, Math.random());
                i++;
            }
            var nodeType = this.getNodeType(builder);
            output = buffer(array, 'vec4', object.count).element(instanceIndex).convert(nodeType);
        } else {
            output = float(0.0);
        }
        return output;
    }
}

@:export(default)
var RangeNode = RangeNode;

@:export
var range = nodeProxy(RangeNode);

addNodeClass('RangeNode', RangeNode);