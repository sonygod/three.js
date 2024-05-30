import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.math.OperatorNode.add;
import three.examples.jsm.nodes.accessors.ModelNode.modelNormalMatrix;
import three.examples.jsm.nodes.accessors.NormalNode.normalView;
import three.examples.jsm.nodes.accessors.PositionNode.positionView;
import three.examples.jsm.nodes.accessors.AccessorsUtils.TBNViewMatrix;
import three.examples.jsm.nodes.accessors.UVNode.uv;
import three.examples.jsm.nodes.nodes.FrontFacingNode.faceDirection;
import three.examples.jsm.nodes.core.Node.addNodeClass;
import three.examples.jsm.nodes.shadernode.ShaderNode.addNodeElement;
import three.examples.jsm.nodes.shadernode.ShaderNode.tslFn;
import three.examples.jsm.nodes.shadernode.ShaderNode.nodeProxy;
import three.examples.jsm.nodes.shadernode.ShaderNode.vec3;
import three.examples.jsm.nodes.three.TangentSpaceNormalMap;
import three.examples.jsm.nodes.three.ObjectSpaceNormalMap;

class NormalMapNode extends TempNode {

	public function new(node:Dynamic, scaleNode:Dynamic = null) {
		super('vec3');
		this.node = node;
		this.scaleNode = scaleNode;
		this.normalMapType = TangentSpaceNormalMap;
	}

	public function setup(builder:Dynamic):Dynamic {
		var normalMapType = this.normalMapType;
		var scaleNode = this.scaleNode;
		var normalMap = this.node.mul(2.0).sub(1.0);
		if (scaleNode !== null) {
			normalMap = vec3(normalMap.xy.mul(scaleNode), normalMap.z);
		}
		var outputNode = null;
		if (normalMapType === ObjectSpaceNormalMap) {
			outputNode = modelNormalMatrix.mul(normalMap).normalize();
		} else if (normalMapType === TangentSpaceNormalMap) {
			var tangent = builder.hasGeometryAttribute('tangent');
			if (tangent === true) {
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

var normalMap = nodeProxy(NormalMapNode);
addNodeElement('normalMap', normalMap);
addNodeClass('NormalMapNode', NormalMapNode);