import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import CameraNode from "../accessors/CameraNode";
import PositionNode from "../accessors/PositionNode";
import ViewportDepthTextureNode from "./ViewportDepthTextureNode";

class ViewportDepthNode extends Node {

	public var scope: String;
	public var valueNode: Node;

	public function new(scope: String, valueNode: Node = null) {
		super("float");
		this.scope = scope;
		this.valueNode = valueNode;
		this.isViewportDepthNode = true;
	}

	override public function generate(builder: Any): Any {
		if (scope == DEPTH_PIXEL) {
			return builder.getFragDepth();
		}
		return super.generate(builder);
	}

	override public function setup(builder: Any): Node {
		var node: Node = null;

		switch (scope) {
			case DEPTH:
				node = viewZToOrthographicDepth(PositionNode.positionView.z, CameraNode.cameraNear, CameraNode.cameraFar);
				break;
			case DEPTH_TEXTURE:
				var texture: Node = (valueNode != null) ? valueNode : ViewportDepthTextureNode.viewportDepthTexture();
				var viewZ: Node = perspectiveDepthToViewZ(texture, CameraNode.cameraNear, CameraNode.cameraFar);
				node = viewZToOrthographicDepth(viewZ, CameraNode.cameraNear, CameraNode.cameraFar);
				break;
			case DEPTH_PIXEL:
				if (valueNode != null) {
					node = depthPixelBase().assign(valueNode);
				}
				break;
		}

		return node;
	}

	static public var DEPTH: String = "depth";
	static public var DEPTH_TEXTURE: String = "depthTexture";
	static public var DEPTH_PIXEL: String = "depthPixel";
}

// NOTE: viewZ, the z-coordinate in camera space, is negative for points in front of the camera

// -near maps to 0; -far maps to 1
public function viewZToOrthographicDepth(viewZ: Node, near: Node, far: Node): Node {
	return viewZ.add(near).div(near.sub(far));
}

// maps orthographic depth in [ 0, 1 ] to viewZ
public function orthographicDepthToViewZ(depth: Node, near: Node, far: Node): Node {
	return near.sub(far).mul(depth).sub(near);
}

// NOTE: https://twitter.com/gonnavis/status/1377183786949959682

// -near maps to 0; -far maps to 1
public function viewZToPerspectiveDepth(viewZ: Node, near: Node, far: Node): Node {
	return near.add(viewZ).mul(far).div(far.sub(near).mul(viewZ));
}

// maps perspective depth in [ 0, 1 ] to viewZ
public function perspectiveDepthToViewZ(depth: Node, near: Node, far: Node): Node {
	return near.mul(far).div(far.sub(near).mul(depth).sub(far));
}

var depthPixelBase: Node = ShaderNode.nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

public var depth: Node = ShaderNode.nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH);
public var depthTexture: Node = ShaderNode.nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_TEXTURE);
public var depthPixel: Node = ShaderNode.nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

depthPixel.assign = function(value: Node): Node {
	return depthPixelBase(value);
};

ShaderNode.addNodeClass("ViewportDepthNode", ViewportDepthNode);