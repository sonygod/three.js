import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.nodes.ReferenceNode;
import three.js.examples.jsm.nodes.math.OperatorNode;
import three.js.examples.jsm.nodes.nodes.NormalNode;
import three.js.examples.jsm.nodes.nodes.PositionNode;
import three.js.examples.jsm.nodes.nodes.TangentNode;
import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.nodes.BufferNode;

class SkinningNode extends Node {

	public function new(skinnedMesh:Dynamic, useReference:Bool = false) {
		super('void');

		this.skinnedMesh = skinnedMesh;
		this.useReference = useReference;

		this.updateType = NodeUpdateType.OBJECT;

		this.skinIndexNode = AttributeNode.attribute('skinIndex', 'uvec4');
		this.skinWeightNode = AttributeNode.attribute('skinWeight', 'vec4');

		var bindMatrixNode:Dynamic;
		var bindMatrixInverseNode:Dynamic;
		var boneMatricesNode:Dynamic;

		if (useReference) {
			bindMatrixNode = ReferenceNode.reference('bindMatrix', 'mat4');
			bindMatrixInverseNode = ReferenceNode.reference('bindMatrixInverse', 'mat4');
			boneMatricesNode = ReferenceNode.referenceBuffer('skeleton.boneMatrices', 'mat4', skinnedMesh.skeleton.bones.length);
		} else {
			bindMatrixNode = UniformNode.uniform(skinnedMesh.bindMatrix, 'mat4');
			bindMatrixInverseNode = UniformNode.uniform(skinnedMesh.bindMatrixInverse, 'mat4');
			boneMatricesNode = BufferNode.buffer(skinnedMesh.skeleton.boneMatrices, 'mat4', skinnedMesh.skeleton.bones.length);
		}

		this.bindMatrixNode = bindMatrixNode;
		this.bindMatrixInverseNode = bindMatrixInverseNode;
		this.boneMatricesNode = boneMatricesNode;
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

		var skinVertex = bindMatrixNode.mul(PositionNode.positionLocal);

		var skinned = OperatorNode.add(
			boneMatX.mul(skinWeightNode.x).mul(skinVertex),
			boneMatY.mul(skinWeightNode.y).mul(skinVertex),
			boneMatZ.mul(skinWeightNode.z).mul(skinVertex),
			boneMatW.mul(skinWeightNode.w).mul(skinVertex)
		);

		var skinPosition = bindMatrixInverseNode.mul(skinned).xyz;

		var skinMatrix = OperatorNode.add(
			skinWeightNode.x.mul(boneMatX),
			skinWeightNode.y.mul(boneMatY),
			skinWeightNode.z.mul(boneMatZ),
			skinWeightNode.w.mul(boneMatW)
		);

		skinMatrix = bindMatrixInverseNode.mul(skinMatrix).mul(bindMatrixNode);

		var skinNormal = skinMatrix.transformDirection(NormalNode.normalLocal).xyz;

		PositionNode.positionLocal.assign(skinPosition);
		NormalNode.normalLocal.assign(skinNormal);

		if (builder.hasGeometryAttribute('tangent')) {
			TangentNode.tangentLocal.assign(skinNormal);
		}
	}

	public function generate(builder:Dynamic, output:Dynamic) {
		if (output !== 'void') {
			return PositionNode.positionLocal.build(builder, output);
		}
	}

	public function update(frame:Dynamic) {
		var object = this.useReference ? frame.object : this.skinnedMesh;
		object.skeleton.update();
	}
}

static function skinning(skinnedMesh:Dynamic) {
	return ShaderNode.nodeObject(new SkinningNode(skinnedMesh));
}

static function skinningReference(skinnedMesh:Dynamic) {
	return ShaderNode.nodeObject(new SkinningNode(skinnedMesh, true));
}

Node.addNodeClass('SkinningNode', SkinningNode);