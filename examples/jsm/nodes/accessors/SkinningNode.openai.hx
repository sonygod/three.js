package three.js.examples.jam.nodes.accessors;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js.core.AttributeNode;
import three.js.core.OperatorNode;
import three.js.nodes.NormalNode;
import three.js.nodes.PositionNode;
import three.js.nodes.TangentNode;
import three.js.core.UniformNode;
import three.js.nodes.BufferNode;
import three.js.nodes.ReferenceNode;

class SkinningNode extends Node {
  public var skinnedMesh:Dynamic;
  public var useReference:Bool;

  public var updateType:NodeUpdateType;

  public var skinIndexNode:AttributeNode;
  public var skinWeightNode:AttributeNode;

  public var bindMatrixNode:Node;
  public var bindMatrixInverseNode:Node;
  public var boneMatricesNode:Node;

  public function new(skinnedMesh:Dynamic, useReference:Bool = false) {
    super('void');

    this.skinnedMesh = skinnedMesh;
    this.useReference = useReference;

    updateType = NodeUpdateType.OBJECT;

    skinIndexNode = AttributeNode.create('skinIndex', 'uvec4');
    skinWeightNode = AttributeNode.create('skinWeight', 'vec4');

    if (useReference) {
      bindMatrixNode = ReferenceNode.create('bindMatrix', 'mat4');
      bindMatrixInverseNode = ReferenceNode.create('bindMatrixInverse', 'mat4');
      boneMatricesNode = ReferenceNode.createBuffer('skeleton.boneMatrices', 'mat4', skinnedMesh.skeleton.bones.length);
    } else {
      bindMatrixNode = UniformNode.create(skinnedMesh.bindMatrix, 'mat4');
      bindMatrixInverseNode = UniformNode.create(skinnedMesh.bindMatrixInverse, 'mat4');
      boneMatricesNode = BufferNode.create(skinnedMesh.skeleton.boneMatrices, 'mat4', skinnedMesh.skeleton.bones.length);
    }
  }

  public function setup(builder:Dynamic) {
    var skinIndexNode = this.skinIndexNode;
    var skinWeightNode = this.skinWeightNode;
    var bindMatrixNode = this.bindMatrixNode;
    var bindMatrixInverseNode = this.bindMatrixInverseNode;
    var boneMatricesNode = this.boneMatricesNode;

    var boneMatX = boneMatricesNode.element(skinIndexNode.x);
    var boneMatY = boneMatricesNode.element(skinIndexNode.y);
    var boneMatZ = boneMatricesNode.element(skinIndexNode.z);
    var boneMatW = boneMatricesNode.element(skinIndexNode.w);

    // POSITION

    var skinVertex = bindMatrixNode.mul(PositionNode.getLocal());
    var skinned = OperatorNode.add(
      boneMatX.mul(skinWeightNode.x).mul(skinVertex),
      boneMatY.mul(skinWeightNode.y).mul(skinVertex),
      boneMatZ.mul(skinWeightNode.z).mul(skinVertex),
      boneMatW.mul(skinWeightNode.w).mul(skinVertex)
    );

    var skinPosition = bindMatrixInverseNode.mul(skinned).xyz;

    // NORMAL

    var skinMatrix = OperatorNode.add(
      skinWeightNode.x.mul(boneMatX),
      skinWeightNode.y.mul(boneMatY),
      skinWeightNode.z.mul(boneMatZ),
      skinWeightNode.w.mul(boneMatW)
    );

    skinMatrix = bindMatrixInverseNode.mul(skinMatrix).mul(bindMatrixNode);

    var skinNormal = skinMatrix.transformDirection(NormalNode.getLocal()).xyz;

    // ASSIGNS

    PositionNode.getLocal().assign(skinPosition);
    NormalNode.getLocal().assign(skinNormal);

    if (builder.hasGeometryAttribute('tangent')) {
      TangentNode.getLocal().assign(skinNormal);
    }
  }

  public function generate(builder:Dynamic, output:String) {
    if (output != 'void') {
      return PositionNode.getLocal().build(builder, output);
    }
  }

  public function update(frame:Dynamic) {
    var object:Dynamic = useReference ? frame.object : skinnedMesh;
    object.skeleton.update();
  }
}

class Skinning {
  public static function skinning(skinnedMesh:Dynamic) {
    return new ShaderNode(new SkinningNode(skinnedMesh));
  }

  public static function skinningReference(skinnedMesh:Dynamic) {
    return new ShaderNode(new SkinningNode(skinnedMesh, true));
  }
}

Node.addNodeClass('SkinningNode', SkinningNode);