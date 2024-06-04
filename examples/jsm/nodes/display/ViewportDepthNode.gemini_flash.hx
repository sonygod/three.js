import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import CameraNode from "../accessors/CameraNode";
import PositionNode from "../accessors/PositionNode";
import ViewportDepthTextureNode from "./ViewportDepthTextureNode";

class ViewportDepthNode extends Node {

	public scope: String;
	public valueNode: Node;

	public constructor(scope: String, valueNode: Node = null) {
		super("float");
		this.scope = scope;
		this.valueNode = valueNode;
		this.isViewportDepthNode = true;
	}

	public generate(builder: Any): Any {
		if (this.scope == ViewportDepthNode.DEPTH_PIXEL) {
			return builder.getFragDepth();
		}
		return super.generate(builder);
	}

	public setup(): Node {
		var node: Node = null;
		if (this.scope == ViewportDepthNode.DEPTH) {
			node = viewZToOrthographicDepth(PositionNode.positionView.z, CameraNode.cameraNear, CameraNode.cameraFar);
		} else if (this.scope == ViewportDepthNode.DEPTH_TEXTURE) {
			var texture: Node = this.valueNode != null ? this.valueNode : ViewportDepthTextureNode.viewportDepthTexture();
			var viewZ: Node = perspectiveDepthToViewZ(texture, CameraNode.cameraNear, CameraNode.cameraFar);
			node = viewZToOrthographicDepth(viewZ, CameraNode.cameraNear, CameraNode.cameraFar);
		} else if (this.scope == ViewportDepthNode.DEPTH_PIXEL) {
			if (this.valueNode != null) {
				node = depthPixelBase().assign(this.valueNode);
			}
		}
		return node;
	}

}

// NOTE: viewZ, the z-coordinate in camera space, is negative for points in front of the camera

// -near maps to 0; -far maps to 1
export function viewZToOrthographicDepth(viewZ: Node, near: Node, far: Node): Node {
	return viewZ.add(near).div(near.sub(far));
}

// maps orthographic depth in [ 0, 1 ] to viewZ
export function orthographicDepthToViewZ(depth: Node, near: Node, far: Node): Node {
	return near.sub(far).mul(depth).sub(near);
}

// NOTE: https://twitter.com/gonnavis/status/1377183786949959682

// -near maps to 0; -far maps to 1
export function viewZToPerspectiveDepth(viewZ: Node, near: Node, far: Node): Node {
	return near.add(viewZ).mul(far).div(far.sub(near).mul(viewZ));
}

// maps perspective depth in [ 0, 1 ] to viewZ
export function perspectiveDepthToViewZ(depth: Node, near: Node, far: Node): Node {
	return near.mul(far).div(far.sub(near).mul(depth).sub(far));
}

ViewportDepthNode.DEPTH = "depth";
ViewportDepthNode.DEPTH_TEXTURE = "depthTexture";
ViewportDepthNode.DEPTH_PIXEL = "depthPixel";

export default ViewportDepthNode;

var depthPixelBase: Node = ShaderNode.nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

export var depth: Node = ShaderNode.nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH);
export var depthTexture: Node = ShaderNode.nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_TEXTURE);
export var depthPixel: Node = ShaderNode.nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

depthPixel.assign = function(value: Node) {
	return depthPixelBase(value);
};

Node.addNodeClass("ViewportDepthNode", ViewportDepthNode);