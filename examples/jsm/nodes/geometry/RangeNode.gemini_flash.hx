import Node from "../core/Node";
import NodeUtils from "../core/NodeUtils";
import BufferNode from "../accessors/BufferNode";
import IndexNode from "../core/IndexNode";
import ShaderNode from "../shadernode/ShaderNode";
import { Vector4, MathUtils } from "three";

class RangeNode extends Node {
  public minNode: ShaderNode;
  public maxNode: ShaderNode;

  public constructor(minNode: ShaderNode = new ShaderNode.Float(), maxNode: ShaderNode = new ShaderNode.Float()) {
    super();
    this.minNode = minNode;
    this.maxNode = maxNode;
  }

  public getVectorLength(builder: any): Int {
    var minLength = builder.getTypeLength(NodeUtils.getValueType(this.minNode.value));
    var maxLength = builder.getTypeLength(NodeUtils.getValueType(this.maxNode.value));
    return minLength > maxLength ? minLength : maxLength;
  }

  public getNodeType(builder: any): String {
    return builder.object.isInstancedMesh ? builder.getTypeFromLength(this.getVectorLength(builder)) : "float";
  }

  public setup(builder: any): ShaderNode {
    var object = builder.object;
    var output: ShaderNode = null;

    if (object.isInstancedMesh) {
      var minValue = this.minNode.value;
      var maxValue = this.maxNode.value;

      var minLength = builder.getTypeLength(NodeUtils.getValueType(minValue));
      var maxLength = builder.getTypeLength(NodeUtils.getValueType(maxValue));

      var min: Vector4 = new Vector4();
      var max: Vector4 = new Vector4();

      min.setScalar(0);
      max.setScalar(0);

      if (minLength == 1) min.setScalar(minValue);
      else if (minValue.isColor) min.set(minValue.r, minValue.g, minValue.b);
      else min.set(minValue.x, minValue.y, minValue.z || 0, minValue.w || 0);

      if (maxLength == 1) max.setScalar(maxValue);
      else if (maxValue.isColor) max.set(maxValue.r, maxValue.g, maxValue.b);
      else max.set(maxValue.x, maxValue.y, maxValue.z || 0, maxValue.w || 0);

      var stride = 4;
      var length = stride * object.count;
      var array = new Float32Array(length);

      for (var i = 0; i < length; i++) {
        var index = i % stride;
        var minElementValue = min.getComponent(index);
        var maxElementValue = max.getComponent(index);
        array[i] = MathUtils.lerp(minElementValue, maxElementValue, Math.random());
      }

      var nodeType = this.getNodeType(builder);

      output = new BufferNode(array, "vec4", object.count).element(new IndexNode()).convert(nodeType);
      //output = bufferAttribute( array, 'vec4', 4, 0 ).convert( nodeType );
    } else {
      output = new ShaderNode.Float(0);
    }

    return output;
  }
}

export default RangeNode;

export var range: any = ShaderNode.nodeProxy(RangeNode);

Node.addNodeClass("RangeNode", RangeNode);