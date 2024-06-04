import TempNode from "../core/TempNode";
import UVNode from "../accessors/UVNode";
import {addNodeClass, addNodeElement, nodeProxy, tslFn} from "../shadernode/ShaderNode";

class CheckerNode extends TempNode {

	public var uvNode:UVNode;

	public function new(uvNode:UVNode = new UVNode()) {
		super("float");
		this.uvNode = uvNode;
	}

	override public function setup():Dynamic {
		return checkerShaderNode({uv: this.uvNode});
	}

}

var checkerShaderNode = tslFn(function(inputs:Dynamic) {
	var uv = inputs.uv.mul(2.0);
	var cx = uv.x.floor();
	var cy = uv.y.floor();
	var result = cx.add(cy).mod(2.0);
	return result.sign();
});

export var checker = nodeProxy(CheckerNode);
addNodeElement("checker", checker);
addNodeClass("CheckerNode", CheckerNode);