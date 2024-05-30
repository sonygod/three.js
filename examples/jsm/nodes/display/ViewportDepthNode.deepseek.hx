import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.accessors.CameraNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.display.ViewportDepthTextureNode;

class ViewportDepthNode extends Node {

	public static var DEPTH:String = 'depth';
	public static var DEPTH_TEXTURE:String = 'depthTexture';
	public static var DEPTH_PIXEL:String = 'depthPixel';

	public var scope:String;
	public var valueNode:ShaderNode;

	public var isViewportDepthNode:Bool = true;

	public function new(scope:String, valueNode:ShaderNode = null) {
		super('float');
		this.scope = scope;
		this.valueNode = valueNode;
	}

	public function generate(builder:ShaderNode):ShaderNode {
		if (this.scope == ViewportDepthNode.DEPTH_PIXEL) {
			return builder.getFragDepth();
		}
		return super.generate(builder);
	}

	public function setup(builder:ShaderNode):ShaderNode {
		var node:ShaderNode = null;
		if (this.scope == ViewportDepthNode.DEPTH) {
			node = viewZToOrthographicDepth(PositionNode.positionView.z, CameraNode.cameraNear, CameraNode.cameraFar);
		} else if (this.scope == ViewportDepthNode.DEPTH_TEXTURE) {
			var texture:ShaderNode = this.valueNode ? this.valueNode : ViewportDepthTextureNode.viewportDepthTexture();
			var viewZ:ShaderNode = perspectiveDepthToViewZ(texture, CameraNode.cameraNear, CameraNode.cameraFar);
			node = viewZToOrthographicDepth(viewZ, CameraNode.cameraNear, CameraNode.cameraFar);
		} else if (this.scope == ViewportDepthNode.DEPTH_PIXEL) {
			if (this.valueNode != null) {
				node = depthPixelBase().assign(this.valueNode);
			}
		}
		return node;
	}

	public static function viewZToOrthographicDepth(viewZ:ShaderNode, near:ShaderNode, far:ShaderNode):ShaderNode {
		return viewZ.add(near).div(near.sub(far));
	}

	public static function orthographicDepthToViewZ(depth:ShaderNode, near:ShaderNode, far:ShaderNode):ShaderNode {
		return near.sub(far).mul(depth).sub(near);
	}

	public static function viewZToPerspectiveDepth(viewZ:ShaderNode, near:ShaderNode, far:ShaderNode):ShaderNode {
		return near.add(viewZ).mul(far).div(far.sub(near).mul(viewZ));
	}

	public static function perspectiveDepthToViewZ(depth:ShaderNode, near:ShaderNode, far:ShaderNode):ShaderNode {
		return near.mul(far).div(far.sub(near).mul(depth).sub(far));
	}

	public static function depthPixelBase():ShaderNode {
		return ShaderNode.nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);
	}

	public static function depth():ShaderNode {
		return ShaderNode.nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH);
	}

	public static function depthTexture():ShaderNode {
		return ShaderNode.nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_TEXTURE);
	}

	public static function depthPixel():ShaderNode {
		return ShaderNode.nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);
	}

	public static function depthPixelAssign(value:ShaderNode):ShaderNode {
		return depthPixelBase().assign(value);
	}

	public static function addNodeClass(name:String, node:Node):Void {
		// TODO: Implement this method
	}
}