import TempNode from '../core/TempNode.hx';
import UvNode from '../accessors/UVNode.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

class CheckerNode extends TempNode {
	public constructor(uvNode: UvNode = UvNode.DEFAULT) {
		super('float');
		this.uvNode = uvNode;
	}

	public setup(): String {
		var uv = this.uvNode.clone();
		uv.multiply(2.0);
		var cx = uv.x.floor();
		var cy = uv.y.floor();
		var result = cx.add(cy).mod(2.0);
		return result.sign();
	}
}

class CheckerShaderNode {
	public staticfromFunction(inputs: {uv: ShaderNode}): ShaderNode {
		var uv = inputs.uv.mul(2.0);
		var cx = uv.x.floor();
		var cy = uv.y.floor();
		var result = cx.add(cy).mod(2.0);
		return result.sign();
	}
}

ShaderNode.fromFunctionToClass(CheckerShaderNode, CheckerNode);

class CheckerNode_ {
	public static checker = ShaderNode.fromFunction(CheckerShaderNode.fromFunction);
}

ShaderNode.addElement('checker', CheckerNode_.checker);

TempNode.addNodeClass('CheckerNode', CheckerNode);