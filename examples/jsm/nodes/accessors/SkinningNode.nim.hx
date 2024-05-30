import Node, { addNodeClass } from '../core/Node.js';
import { NodeUpdateType } from '../core/constants.js';
import { nodeObject } from '../shadernode/ShaderNode.js';
import { attribute } from '../core/AttributeNode.js';
import { reference, referenceBuffer } from './ReferenceNode.js';
import { add } from '../math/OperatorNode.js';
import { normalLocal } from './NormalNode.js';
import { positionLocal } from './PositionNode.js';
import { tangentLocal } from './TangentNode.js';
import { uniform } from '../core/UniformNode.js';
import { buffer } from './BufferNode.js';

class SkinningNode extends Node {

	public var skinnedMesh:Dynamic;
	public var useReference:Bool;

	public var updateType:NodeUpdateType = NodeUpdateType.OBJECT;

	public var skinIndexNode:AttributeNode;
	public var skinWeightNode:AttributeNode;

	public var bindMatrixNode:Dynamic;
	public var bindMatrixInverseNode:Dynamic;
	public var boneMatricesNode:Dynamic;

	public function new( skinnedMesh:Dynamic, useReference:Bool = false ) {

		super('void');

		this.skinnedMesh = skinnedMesh;
		this.useReference = useReference;

		this.skinIndexNode = attribute('skinIndex', 'uvec4');
		this.skinWeightNode = attribute('skinWeight', 'vec4');

		if (useReference) {

			this.bindMatrixNode = reference('bindMatrix', 'mat4');
			this.bindMatrixInverseNode = reference('bindMatrixInverse', 'mat4');
			this.boneMatricesNode = referenceBuffer('skeleton.boneMatrices', 'mat4', skinnedMesh.skeleton.bones.length);

		} else {

			this.bindMatrixNode = uniform(skinnedMesh.bindMatrix, 'mat4');
			this.bindMatrixInverseNode = uniform(skinnedMesh.bindMatrixInverse, 'mat4');
			this.boneMatricesNode = buffer(skinnedMesh.skeleton.boneMatrices, 'mat4', skinnedMesh.skeleton.bones.length);

		}

	}

	public function setup( builder:Dynamic ) {

		const { skinIndexNode, skinWeightNode, bindMatrixNode, bindMatrixInverseNode, boneMatricesNode } = this;

		const boneMatX = boneMatricesNode.element(skinIndexNode.x);
		const boneMatY = boneMatricesNode.element(skinIndexNode.y);
		const boneMatZ = boneMatricesNode.element(skinIndexNode.z);
		const boneMatW = boneMatricesNode.element(skinIndexNode.w);

		// POSITION

		const skinVertex = bindMatrixNode.mul(positionLocal);

		const skinned = add(
			boneMatX.mul(skinWeightNode.x).mul(skinVertex),
			boneMatY.mul(skinWeightNode.y).mul(skinVertex),
			boneMatZ.mul(skinWeightNode.z).mul(skinVertex),
			boneMatW.mul(skinWeightNode.w).mul(skinVertex)
		);

		const skinPosition = bindMatrixInverseNode.mul(skinned).xyz;

		// NORMAL

		let skinMatrix = add(
			skinWeightNode.x.mul(boneMatX),
			skinWeightNode.y.mul(boneMatY),
			skinWeightNode.z.mul(boneMatZ),
			skinWeightNode.w.mul(boneMatW)
		);

		skinMatrix = bindMatrixInverseNode.mul(skinMatrix).mul(bindMatrixNode);

		const skinNormal = skinMatrix.transformDirection(normalLocal).xyz;

		// ASSIGNS

		positionLocal.assign(skinPosition);
		normalLocal.assign(skinNormal);

		if (builder.hasGeometryAttribute('tangent')) {

			tangentLocal.assign(skinNormal);

		}

	}

	public function generate( builder:Dynamic, output:String ) {

		if (output != 'void') {

			return positionLocal.build(builder, output);

		}

	}

	public function update( frame:Dynamic ) {

		const object = this.useReference ? frame.object : this.skinnedMesh;

		object.skeleton.update();

	}

}

export default SkinningNode;

export function skinning( skinnedMesh:Dynamic ) {

	return nodeObject(new SkinningNode(skinnedMesh));

}

export function skinningReference( skinnedMesh:Dynamic ) {

	return nodeObject(new SkinningNode(skinnedMesh, true));

}

addNodeClass('SkinningNode', SkinningNode);