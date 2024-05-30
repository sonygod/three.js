package three.js.nodes.display;

import three.js.nodes.core.Node;
import three.js.nodes.shadernode.ShaderNode;
import three.js.accessors.CameraNode;
import three.js.accessors.PositionNode;
import three.js.nodes.display.ViewportDepthTextureNode;

class ViewportDepthNode extends Node {

	public var scope:String;
	public var valueNode:Node;

	public var isViewportDepthNode:Bool = true;

	public function new(scope:String, valueNode:Node = null) {
		super('float');
		this.scope = scope;
		this.valueNode = valueNode;
	}

	override public function generate(builder:Dynamic):Dynamic {
		if (scope == ViewportDepthNode.DEPTH_PIXEL) {
			return builder.getFragDepth();
		}
		return super.generate(builder);
	}

	public function setup(builder:Dynamic):Node {
		var node:Node = null;
		switch (scope) {
			case ViewportDepthNode.DEPTH:
				node = viewZToOrthographicDepth(positionView.z, cameraNear, cameraFar);
			case ViewportDepthNode.DEPTH_TEXTURE:
				var texture:Node = valueNode != null ? valueNode : viewportDepthTexture();
				var viewZ:Float = perspectiveDepthToViewZ(texture, cameraNear, cameraFar);
				node = viewZToOrthographicDepth(viewZ, cameraNear, cameraFar);
			case ViewportDepthNode.DEPTH_PIXEL:
				if (valueNode != null) {
					node = depthPixelBase().assign(valueNode);
				}
		}
		return node;
	}

	static public inline function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
		return viewZ + near / (near - far);
	}

	static public inline function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
		return near - far * depth - near;
	}

	static public inline function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
		return near + viewZ * far / (far - near * viewZ);
	}

	static public inline function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
		return near * far / (far - near * depth - far);
	}

}

class ViewportDepthNode {

	static public inline var DEPTH:String = 'depth';
	static public inline var DEPTH_TEXTURE:String = 'depthTexture';
	static public inline var DEPTH_PIXEL:String = 'depthPixel';

	static public var depth:Node = nodeImmutable( DEPTH );
	static public var depthTexture:Node = nodeProxy( DEPTH_TEXTURE );
	static public var depthPixel:Node = nodeImmutable( DEPTH_PIXEL );

	static public function addAssign( value:Node ):Node {
		return depthPixelBase().assign( value );
	}

}