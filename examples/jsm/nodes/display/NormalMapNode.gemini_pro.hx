import TempNode from "../core/TempNode";
import OperatorNode from "../math/OperatorNode";
import ModelNode from "../accessors/ModelNode";
import NormalNode from "../accessors/NormalNode";
import PositionNode from "../accessors/PositionNode";
import AccessorsUtils from "../accessors/AccessorsUtils";
import UVNode from "../accessors/UVNode";
import FrontFacingNode from "./FrontFacingNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

import {TangentSpaceNormalMap, ObjectSpaceNormalMap} from "three";

// Normal Mapping Without Precomputed Tangents
// http://www.thetenthplanet.de/archives/1180

var perturbNormal2Arb = ShaderNode.tslFn((inputs) => {

	var eye_pos = inputs.eye_pos;
	var surf_norm = inputs.surf_norm;
	var mapN = inputs.mapN;
	var uv = inputs.uv;

	var q0 = eye_pos.dFdx();
	var q1 = eye_pos.dFdy();
	var st0 = uv.dFdx();
	var st1 = uv.dFdy();

	var N = surf_norm; // normalized

	var q1perp = q1.cross(N);
	var q0perp = N.cross(q0);

	var T = q1perp.mul(st0.x).add(q0perp.mul(st1.x));
	var B = q1perp.mul(st0.y).add(q0perp.mul(st1.y));

	var det = T.dot(T).max(B.dot(B));
	var scale = FrontFacingNode.faceDirection.mul(det.inverseSqrt());

	return OperatorNode.add(T.mul(mapN.x, scale), B.mul(mapN.y, scale), N.mul(mapN.z)).normalize();

});

class NormalMapNode extends TempNode {

	public node:Node;
	public scaleNode:Node;
	public normalMapType:Int;

	public constructor(node:Node, scaleNode:Node = null) {

		super("vec3");

		this.node = node;
		this.scaleNode = scaleNode;

		this.normalMapType = TangentSpaceNormalMap;

	}

	public setup(builder:any):Node {

		var normalMapType = this.normalMapType;
		var scaleNode = this.scaleNode;

		var normalMap = this.node.mul(2.0).sub(1.0);

		if (scaleNode != null) {

			normalMap = ShaderNode.vec3(normalMap.xy.mul(scaleNode), normalMap.z);

		}

		var outputNode:Node = null;

		if (normalMapType == ObjectSpaceNormalMap) {

			outputNode = ModelNode.modelNormalMatrix.mul(normalMap).normalize();

		} else if (normalMapType == TangentSpaceNormalMap) {

			var tangent = builder.hasGeometryAttribute("tangent");

			if (tangent == true) {

				outputNode = AccessorsUtils.TBNViewMatrix.mul(normalMap).normalize();

			} else {

				outputNode = perturbNormal2Arb({
					eye_pos: PositionNode.positionView,
					surf_norm: NormalNode.normalView,
					mapN: normalMap,
					uv: UVNode.uv()
				});

			}

		}

		return outputNode;

	}

}

export default NormalMapNode;

export var normalMap = ShaderNode.nodeProxy(NormalMapNode);

ShaderNode.addNodeElement("normalMap", normalMap);

Node.addNodeClass("NormalMapNode", NormalMapNode);