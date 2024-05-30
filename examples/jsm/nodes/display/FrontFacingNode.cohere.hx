import Node from '../core/Node.hx';
import { nodeImmutable, float } from '../shadernode/ShaderNode.hx';
import { BackSide, WebGLCoordinateSystem } from 'three';

class FrontFacingNode extends Node {
	public constructor() {
		super('bool');
		this.isFrontFacingNode = true;
	}

	public function generate(builder:Dynamic) {
		var renderer = builder.renderer;
		var material = builder.material;

		if (renderer.coordinateSystem == WebGLCoordinateSystem) {
			if (material.side == BackSide) {
				return 'false';
			}
		}

		return builder.getFrontFacing();
	}
}

class FrontFacing {
	public static function frontFacing() {
		return nodeImmutable(FrontFacingNode);
	}

	public static function faceDirection() {
		return float(frontFacing()).mul(2.0).sub(1.0);
	}
}

Node.addNodeClass('FrontFacingNode', FrontFacingNode);

export { FrontFacingNode, FrontFacing };