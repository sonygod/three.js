import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.nodes.NormalNode;
import three.js.examples.jsm.nodes.nodes.PositionNode;
import three.js.examples.jsm.nodes.nodes.TextureNode;
import three.js.examples.jsm.nodes.nodes.TextureSizeNode;
import three.js.examples.jsm.nodes.nodes.TangentNode;

class BatchNode extends Node {

	public var batchMesh:Dynamic;
	public var instanceColorNode:Dynamic;
	public var batchingIdNode:Dynamic;

	public function new(batchMesh:Dynamic) {
		super('void');
		this.batchMesh = batchMesh;
		this.instanceColorNode = null;
		this.batchingIdNode = null;
	}

	public function setup(builder:Dynamic):Void {
		if (this.batchingIdNode == null) {
			this.batchingIdNode = AttributeNode.attribute('batchId');
		}

		var matriceTexture = this.batchMesh._matricesTexture;
		var size = TextureSizeNode.textureSize(TextureNode.textureLoad(matriceTexture), 0);
		var j = ShaderNode.float(ShaderNode.int(this.batchingIdNode)).mul(4).toVar();
		var x = ShaderNode.int(j.mod(size));
		var y = ShaderNode.int(j).div(ShaderNode.int(size));
		var batchingMatrix = ShaderNode.mat4(
			TextureNode.textureLoad(matriceTexture, ShaderNode.ivec2(x, y)),
			TextureNode.textureLoad(matriceTexture, ShaderNode.ivec2(x.add(1), y)),
			TextureNode.textureLoad(matriceTexture, ShaderNode.ivec2(x.add(2), y)),
			TextureNode.textureLoad(matriceTexture, ShaderNode.ivec2(x.add(3), y))
		);

		var bm = ShaderNode.mat3(
			batchingMatrix[0].xyz,
			batchingMatrix[1].xyz,
			batchingMatrix[2].xyz
		);

		PositionNode.positionLocal.assign(batchingMatrix.mul(PositionNode.positionLocal));

		var transformedNormal = NormalNode.normalLocal.div(ShaderNode.vec3(bm[0].dot(bm[0]), bm[1].dot(bm[1]), bm[2].dot(bm[2])));
		var batchingNormal = bm.mul(transformedNormal).xyz;
		NormalNode.normalLocal.assign(batchingNormal);

		if (builder.hasGeometryAttribute('tangent')) {
			TangentNode.tangentLocal.mulAssign(bm);
		}
	}
}

class Batch {
	public static function new(batchMesh:Dynamic):BatchNode {
		return new BatchNode(batchMesh);
	}
}

Node.addNodeClass('batch', BatchNode);