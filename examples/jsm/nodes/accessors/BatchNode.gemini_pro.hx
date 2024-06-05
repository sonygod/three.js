import Node from '../core/Node';
import { normalLocal } from './NormalNode';
import { positionLocal } from './PositionNode';
import { nodeProxy, vec3, mat3, mat4, Int, Ivec2, Float } from '../shadernode/ShaderNode';
import { textureLoad } from './TextureNode';
import { textureSize } from './TextureSizeNode';
import { attribute } from '../core/AttributeNode';
import { tangentLocal } from './TangentNode';

class BatchNode extends Node {

	public batchMesh: Dynamic;

	public instanceColorNode: Node;

	public batchingIdNode: Node;

	public constructor(batchMesh: Dynamic) {
		super('void');
		this.batchMesh = batchMesh;
		this.instanceColorNode = null;
		this.batchingIdNode = null;
	}

	public setup(builder: Dynamic): Void {
		// POSITION
		if (this.batchingIdNode == null) {
			this.batchingIdNode = attribute('batchId');
		}
		var matriceTexture = this.batchMesh._matricesTexture;
		var size = textureSize(textureLoad(matriceTexture), 0);
		var j = new Float(new Int(this.batchingIdNode).toInt()).mul(new Float(4)).toVar();
		var x = new Int(j.mod(size));
		var y = new Int(j).div(new Int(size));
		var batchingMatrix = new mat4(
			textureLoad(matriceTexture, new Ivec2(x, y)),
			textureLoad(matriceTexture, new Ivec2(x.add(new Int(1)), y)),
			textureLoad(matriceTexture, new Ivec2(x.add(new Int(2)), y)),
			textureLoad(matriceTexture, new Ivec2(x.add(new Int(3)), y))
		);
		var bm = new mat3(
			batchingMatrix[0].xyz,
			batchingMatrix[1].xyz,
			batchingMatrix[2].xyz
		);
		positionLocal.assign(batchingMatrix.mul(positionLocal));
		var transformedNormal = normalLocal.div(new vec3(bm[0].dot(bm[0]), bm[1].dot(bm[1]), bm[2].dot(bm[2])));
		var batchingNormal = bm.mul(transformedNormal).xyz;
		normalLocal.assign(batchingNormal);
		if (builder.hasGeometryAttribute('tangent')) {
			tangentLocal.mulAssign(bm);
		}
	}
}

export default BatchNode;

export var batch = nodeProxy(BatchNode);

// Add node class
@:noCompletion
class BatchNodeClass extends Node {
	static var nodeClass: String = 'batch';
}

Node.addNodeClass(BatchNodeClass);