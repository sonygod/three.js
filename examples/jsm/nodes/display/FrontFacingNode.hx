package three.js.examples.nodes.display;

import three.core.Node;
import three.shadernode.ShaderNode;

class FrontFacingNode extends Node {

	public var isFrontFacingNode:Bool = true;

	public function new() {
		super('bool');
	}

	override public function generate(builder:Dynamic) {
		var renderer:Dynamic = builder.renderer;
		var material:Dynamic = builder.material;
		if (renderer.coordinateSystem == WebGLCoordinateSystem) {
			if (material.side == BackSide) {
				return 'false';
			}
		}
		return builder.getFrontFacing();
	}

}

// Exports
@:native('frontFacing')
var frontFacing:ShaderNode = nodeImmutable(new FrontFacingNode());

@:native('faceDirection')
var faceDirection:ShaderNode = float(frontFacing).mul(2.0).sub(1.0);

// Register the node class
Node.addNodeClass('FrontFacingNode', FrontFacingNode);