import Node from "../core/Node";
import NodeUtils from "../core/NodeUtils";
import BufferNode from "../accessors/BufferNode";
//import BufferAttributeNode from "../accessors/BufferAttributeNode";
import IndexNode from "../core/IndexNode";
import ShaderNode from "../shadernode/ShaderNode";
import { Vector4, MathUtils } from "three";

class RangeNode extends Node {
  public minNode: ShaderNode;
  public maxNode: ShaderNode;

  public constructor(minNode: ShaderNode = ShaderNode.float(), maxNode: ShaderNode = ShaderNode.float()) {
    super();
    this.minNode = minNode;
    this.maxNode = maxNode;
  }

  public getVectorLength(builder: any): Int {
    const minLength = builder.getTypeLength(NodeUtils.getValueType(this.minNode.value));
    const maxLength = builder.getTypeLength(NodeUtils.getValueType(this.maxNode.value));
    return minLength > maxLength ? minLength : maxLength;
  }

  public getNodeType(builder: any): String {
    return builder.object.isInstancedMesh === true ? builder.getTypeFromLength(this.getVectorLength(builder)) : "float";
  }

  public setup(builder: any): ShaderNode {
    const object = builder.object;
    var output: ShaderNode;

    if (object.isInstancedMesh === true) {
      const minValue = this.minNode.value;
      const maxValue = this.maxNode.value;

      const minLength = builder.getTypeLength(NodeUtils.getValueType(minValue));
      const maxLength = builder.getTypeLength(NodeUtils.getValueType(maxValue));

      var min: Vector4 = new Vector4();
      var max: Vector4 = new Vector4();

      min.setScalar(0);
      max.setScalar(0);

      if (minLength === 1) min.setScalar(minValue);
      else if (minValue.isColor) min.set(minValue.r, minValue.g, minValue.b);
      else min.set(minValue.x, minValue.y, minValue.z || 0, minValue.w || 0);

      if (maxLength === 1) max.setScalar(maxValue);
      else if (maxValue.isColor) max.set(maxValue.r, maxValue.g, maxValue.b);
      else max.set(maxValue.x, maxValue.y, maxValue.z || 0, maxValue.w || 0);

      const stride = 4;
      const length = stride * object.count;
      const array = new Float32Array(length);

      for (let i = 0; i < length; i++) {
        const index = i % stride;
        const minElementValue = min.getComponent(index);
        const maxElementValue = max.getComponent(index);
        array[i] = MathUtils.lerp(minElementValue, maxElementValue, Math.random());
      }

      const nodeType = this.getNodeType(builder);
      output = BufferNode.buffer(array, "vec4", object.count).element(IndexNode.instanceIndex()).convert(nodeType);
      //output = BufferAttributeNode.bufferAttribute(array, "vec4", 4, 0).convert(nodeType);
    } else {
      output = ShaderNode.float(0);
    }

    return output;
  }
}

export default RangeNode;
export const range = ShaderNode.nodeProxy(RangeNode);
addNodeClass("RangeNode", RangeNode);

function addNodeClass(name: String, clazz: Class<Node>) {
  // No equivalent of addNodeClass in Haxe
  // This function could be used to register the class for later use
}