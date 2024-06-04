import Node from '../core/Node.hx';
import NormalNode from './NormalNode.hx';
import PositionNode from './PositionNode.hx';
import { nodeProxy, vec3, mat3, mat4, ivec2, int, float } from '../shadernode/ShaderNode.hx';
import TextureNode from './TextureNode.hx';
import TextureSizeNode from './TextureSizeNode.hx';
import AttributeNode from '../core/AttributeNode.hx';
import TangentNode from './TangentNode.hx';

class BatchNode extends Node {

	public var batchMesh:Dynamic;

	public var instanceColorNode:Dynamic;

	public var batchingIdNode:Dynamic;

	public function new(batchMesh:Dynamic) {
		super("void");
		this.batchMesh = batchMesh;
	}

	public function setup(builder:Dynamic):Void {

		// POSITION

		if (this.batchingIdNode == null) {

			this.batchingIdNode = AttributeNode.attribute("batchId");

		}

		var matriceTexture = this.batchMesh._matricesTexture;

		var size = TextureSizeNode.textureSize(TextureNode.textureLoad(matriceTexture), 0);
		var j = float(int(this.batchingIdNode)).mul(4).toVar();

		var x = int(j.mod(size));
		var y = int(j).div(int(size));
		var batchingMatrix = mat4(
			TextureNode.textureLoad(matriceTexture, ivec2(x, y)),
			TextureNode.textureLoad(matriceTexture, ivec2(x.add(1), y)),
			TextureNode.textureLoad(matriceTexture, ivec2(x.add(2), y)),
			TextureNode.textureLoad(matriceTexture, ivec2(x.add(3), y))
		);

		var bm = mat3(
			batchingMatrix[0].xyz,
			batchingMatrix[1].xyz,
			batchingMatrix[2].xyz
		);

		PositionNode.positionLocal.assign(batchingMatrix.mul(PositionNode.positionLocal));

		var transformedNormal = NormalNode.normalLocal.div(vec3(bm[0].dot(bm[0]), bm[1].dot(bm[1]), bm[2].dot(bm[2])));

		var batchingNormal = bm.mul(transformedNormal).xyz;

		NormalNode.normalLocal.assign(batchingNormal);

		if (builder.hasGeometryAttribute("tangent")) {

			TangentNode.tangentLocal.mulAssign(bm);

		}

	}

}

export var batch = nodeProxy(BatchNode);

addNodeClass("batch", BatchNode);