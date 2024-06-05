import Node from "../core/Node";
import {NodeUpdateType} from "../core/constants";
import {nodeObject} from "../shadernode/ShaderNode";
import {attribute} from "../core/AttributeNode";
import {reference, referenceBuffer} from "./ReferenceNode";
import {add} from "../math/OperatorNode";
import {normalLocal} from "./NormalNode";
import {positionLocal} from "./PositionNode";
import {tangentLocal} from "./TangentNode";
import {uniform} from "../core/UniformNode";
import {buffer} from "./BufferNode";

class SkinningNode extends Node {

	public skinnedMesh:Dynamic;
	public useReference:Bool;
	public skinIndexNode:Dynamic;
	public skinWeightNode:Dynamic;
	public bindMatrixNode:Dynamic;
	public bindMatrixInverseNode:Dynamic;
	public boneMatricesNode:Dynamic;

	public function new(skinnedMesh:Dynamic, useReference:Bool = false) {
		super("void");
		this.skinnedMesh = skinnedMesh;
		this.useReference = useReference;
		this.updateType = NodeUpdateType.OBJECT;

		this.skinIndexNode = attribute("skinIndex", "uvec4");
		this.skinWeightNode = attribute("skinWeight", "vec4");

		var bindMatrixNode:Dynamic, bindMatrixInverseNode:Dynamic, boneMatricesNode:Dynamic;

		if (useReference) {
			bindMatrixNode = reference("bindMatrix", "mat4");
			bindMatrixInverseNode = reference("bindMatrixInverse", "mat4");
			boneMatricesNode = referenceBuffer("skeleton.boneMatrices", "mat4", skinnedMesh.skeleton.bones.length);
		} else {
			bindMatrixNode = uniform(skinnedMesh.bindMatrix, "mat4");
			bindMatrixInverseNode = uniform(skinnedMesh.bindMatrixInverse, "mat4");
			boneMatricesNode = buffer(skinnedMesh.skeleton.boneMatrices, "mat4", skinnedMesh.skeleton.bones.length);
		}

		this.bindMatrixNode = bindMatrixNode;
		this.bindMatrixInverseNode = bindMatrixInverseNode;
		this.boneMatricesNode = boneMatricesNode;
	}

	public function setup(builder:Dynamic) {
		var {skinIndexNode, skinWeightNode, bindMatrixNode, bindMatrixInverseNode, boneMatricesNode} = this;

		var boneMatX = boneMatricesNode.element(skinIndexNode.x);
		var boneMatY = boneMatricesNode.element(skinIndexNode.y);
		var boneMatZ = boneMatricesNode.element(skinIndexNode.z);
		var boneMatW = boneMatricesNode.element(skinIndexNode.w);

		// POSITION
		var skinVertex = bindMatrixNode.mul(positionLocal);
		var skinned = add(
			boneMatX.mul(skinWeightNode.x).mul(skinVertex),
			boneMatY.mul(skinWeightNode.y).mul(skinVertex),
			boneMatZ.mul(skinWeightNode.z).mul(skinVertex),
			boneMatW.mul(skinWeightNode.w).mul(skinVertex)
		);
		var skinPosition = bindMatrixInverseNode.mul(skinned).xyz;

		// NORMAL
		var skinMatrix = add(
			skinWeightNode.x.mul(boneMatX),
			skinWeightNode.y.mul(boneMatY),
			skinWeightNode.z.mul(boneMatZ),
			skinWeightNode.w.mul(boneMatW)
		);

		skinMatrix = bindMatrixInverseNode.mul(skinMatrix).mul(bindMatrixNode);
		var skinNormal = skinMatrix.transformDirection(normalLocal).xyz;

		// ASSIGNS
		positionLocal.assign(skinPosition);
		normalLocal.assign(skinNormal);

		if (builder.hasGeometryAttribute("tangent")) {
			tangentLocal.assign(skinNormal);
		}
	}

	public function generate(builder:Dynamic, output:String) {
		if (output != "void") {
			return positionLocal.build(builder, output);
		}
	}

	public function update(frame:Dynamic) {
		var object = this.useReference ? frame.object : this.skinnedMesh;
		object.skeleton.update();
	}
}

export var SkinningNode = SkinningNode;

export function skinning(skinnedMesh:Dynamic):Dynamic {
	return nodeObject(new SkinningNode(skinnedMesh));
}

export function skinningReference(skinnedMesh:Dynamic):Dynamic {
	return nodeObject(new SkinningNode(skinnedMesh, true));
}

// addNodeClass( "SkinningNode", SkinningNode );