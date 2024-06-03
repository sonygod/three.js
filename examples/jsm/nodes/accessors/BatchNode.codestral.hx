import Node from '../core/Node.js';
import NodeClass from '../core/NodeClass.js';
import NormalNode from './NormalNode.js';
import PositionNode from './PositionNode.js';
import { NodeProxy, Vec3, Mat3, Mat4, Int, IVec2, Float } from '../shadernode/ShaderNode.js';
import TextureNode from './TextureNode.js';
import TextureSizeNode from './TextureSizeNode.js';
import AttributeNode from '../core/AttributeNode.js';
import TangentNode from './TangentNode.js';

class BatchNode extends Node {

	public var batchMesh:any;
	public var instanceColorNode:Dynamic;
	public var batchingIdNode:Dynamic;

	public function new(batchMesh:any) {
		super('void');

		this.batchMesh = batchMesh;
		this.instanceColorNode = null;
		this.batchingIdNode = null;
	}

	public function setup(builder:Dynamic) {

		if (this.batchingIdNode == null) {
			this.batchingIdNode = AttributeNode.attribute('batchId');
		}

		var matriceTexture = this.batchMesh._matricesTexture;

		var size = TextureSizeNode.textureSize(TextureNode.textureLoad(matriceTexture), 0);
		var j = Std.parseInt(this.batchingIdNode).toFloat();
		j = j * 4;

		var x = Std.parseInt(j % size);
		var y = Std.parseInt(j / size);
		var batchingMatrix = new Mat4(
			TextureNode.textureLoad(matriceTexture, new IVec2(x, y)),
			TextureNode.textureLoad(matriceTexture, new IVec2(x + 1, y)),
			TextureNode.textureLoad(matriceTexture, new IVec2(x + 2, y)),
			TextureNode.textureLoad(matriceTexture, new IVec2(x + 3, y))
		);

		var bm = new Mat3(
			new Vec3(batchingMatrix.get(0, 0), batchingMatrix.get(0, 1), batchingMatrix.get(0, 2)),
			new Vec3(batchingMatrix.get(1, 0), batchingMatrix.get(1, 1), batchingMatrix.get(1, 2)),
			new Vec3(batchingMatrix.get(2, 0), batchingMatrix.get(2, 1), batchingMatrix.get(2, 2))
		);

		PositionNode.positionLocal.assign(batchingMatrix.mul(PositionNode.positionLocal));

		var transformedNormal = NormalNode.normalLocal.div(new Vec3(bm.get(0).dot(bm.get(0)), bm.get(1).dot(bm.get(1)), bm.get(2).dot(bm.get(2))));

		var batchingNormal = bm.mul(transformedNormal);

		NormalNode.normalLocal.assign(new Vec3(batchingNormal.get(0), batchingNormal.get(1), batchingNormal.get(2)));

		if (builder.hasGeometryAttribute('tangent')) {
			TangentNode.tangentLocal.mulAssign(bm);
		}
	}
}

export default BatchNode;

export var batch = NodeProxy.nodeProxy(BatchNode);

NodeClass.addNodeClass('batch', BatchNode);