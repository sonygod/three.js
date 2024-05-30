import TempNode from '../core/TempNode.hx';
import { add } from '../math/OperatorNode.hx';

import { modelNormalMatrix } from '../accessors/ModelNode.hx';
import { normalView } from '../accessors/NormalNode.hx';
import { positionView } from '../accessors/PositionNode.hx';
import { TBNViewMatrix } from '../accessors/AccessorsUtils.hx';
import { uv } from '../accessors/UVNode.hx';
import { faceDirection } from './FrontFacingNode.hx';
import { addNodeClass, addNodeElement, nodeProxy, vec3 } from '../shadernode/ShaderNode.hx';

import { TangentSpaceNormalMap, ObjectSpaceNormalMap } from 'three';

// Normal Mapping Without Precomputed Tangents
// http://www.thetenthplanet.de/archives/1180

const perturbNormal2Arb = (inputs) => {
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
	var scale = faceDirection.mul(det.inverseSqrt());
	return add(T.mul(mapN.x, scale), B.mul(mapN.y, scale), N.mul(mapN.z)).normalize();
};

class NormalMapNode extends TempNode {
	constructor(node, scaleNode = null) {
		super('vec3');
		this.node = node;
		this.scaleNode = scaleNode;
		this.normalMapType = TangentSpaceNormalMap;
	}

	setup(builder) {
		var normalMapType = this.normalMapType;
		var scaleNode = this.scaleNode;
		var normalMap = this.node.mul(2.0).sub(1.0);
		if (scaleNode != null) {
			normalMap = vec3(normalMap.xy.mul(scaleNode), normalMap.z);
		}
		var outputNode = null;
		if (normalMapType == ObjectSpaceNormalMap) {
			outputNode = modelNormalMatrix.mul(normalMap).normalize();
		} else if (normalMapType == TangentSpaceNormalMap) {
			var tangent = builder.hasGeometryAttribute('tangent');
			if (tangent) {
				outputNode = TBNViewMatrix.mul(normalMap).normalize();
			} else {
				outputNode = perturbNormal2Arb({
					eye_pos: positionView,
					surf_norm: normalView,
					mapN: normalMap,
					uv: uv()
				});
			}
		}
		return outputNode;
	}
}

class NormalMapNode_Impl_ {
	static normalMap(_) {
		return nodeProxy(NormalMapNode);
	}
}

addNodeElement('normalMap', NormalMapNode_Impl_.normalMap(_));

addNodeClass('NormalMapNode', NormalMapNode);