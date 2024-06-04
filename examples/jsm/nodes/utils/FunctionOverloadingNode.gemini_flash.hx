import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class FunctionOverloadingNode extends Node {

	public functionNodes:Array<Node>;
	public parametersNodes:Array<Node>;
	private _candidateFnCall:Node;

	public function new(functionNodes:Array<Node> = [], ...parametersNodes:Array<Node>) {
		super();
		this.functionNodes = functionNodes;
		this.parametersNodes = parametersNodes;
		this._candidateFnCall = null;
	}

	public function getNodeType():String {
		return this.functionNodes[0].shaderNode.layout.type;
	}

	public function setup(builder:Dynamic):Dynamic {

		var params = this.parametersNodes;

		var candidateFnCall = this._candidateFnCall;

		if (candidateFnCall == null) {

			var candidateFn:Node = null;
			var candidateScore:Int = -1;

			for (functionNode in this.functionNodes) {

				var shaderNode = functionNode.shaderNode;
				var layout = shaderNode.layout;

				if (layout == null) {

					throw new Error("FunctionOverloadingNode: FunctionNode must be a layout.");

				}

				var inputs = layout.inputs;

				if (params.length == inputs.length) {

					var score:Int = 0;

					for (i in 0...params.length) {

						var param = params[i];
						var input = inputs[i];

						if (param.getNodeType(builder) == input.type) {

							score++;

						} else {

							score = 0;

						}

					}

					if (score > candidateScore) {

						candidateFn = functionNode;
						candidateScore = score;

					}

				}

			}

			this._candidateFnCall = candidateFnCall = candidateFn.call(null, ...params);

		}

		return candidateFnCall;

	}

}

class OverloadingBaseFn extends Node {

	public function new(functionNodes:Array<Node>, ...parametersNodes:Array<Node>):Void {
		super();
		this.functionNodes = functionNodes;
		this.parametersNodes = parametersNodes;
	}

	public function getNodeType():String {
		return this.functionNodes[0].shaderNode.layout.type;
	}

	public function setup(builder:Dynamic):Dynamic {

		var params = this.parametersNodes;

		var candidateFnCall:Node = null;

		var candidateFn:Node = null;
		var candidateScore:Int = -1;

		for (functionNode in this.functionNodes) {

			var shaderNode = functionNode.shaderNode;
			var layout = shaderNode.layout;

			if (layout == null) {

				throw new Error("FunctionOverloadingNode: FunctionNode must be a layout.");

			}

			var inputs = layout.inputs;

			if (params.length == inputs.length) {

				var score:Int = 0;

				for (i in 0...params.length) {

					var param = params[i];
					var input = inputs[i];

					if (param.getNodeType(builder) == input.type) {

						score++;

					} else {

						score = 0;

					}

				}

				if (score > candidateScore) {

					candidateFn = functionNode;
					candidateScore = score;

				}

			}

		}

		candidateFnCall = candidateFn.call(null, ...params);

		return candidateFnCall;

	}

}

var overloadingBaseFn:OverloadingBaseFn = new OverloadingBaseFn();

var overloadingFn = (functionNodes:Array<Node>) => (...params:Array<Node>) => overloadingBaseFn.call(null, functionNodes, ...params);

class FunctionOverloadingNodeProxy extends Node {
	public function new(functionNodes:Array<Node>, ...parametersNodes:Array<Node>):Void {
		super();
		this.functionNodes = functionNodes;
		this.parametersNodes = parametersNodes;
	}
	public function getNodeType():String {
		return this.functionNodes[0].shaderNode.layout.type;
	}
	public function setup(builder:Dynamic):Dynamic {
		var params = this.parametersNodes;
		var candidateFnCall:Node = null;
		var candidateFn:Node = null;
		var candidateScore:Int = -1;
		for (functionNode in this.functionNodes) {
			var shaderNode = functionNode.shaderNode;
			var layout = shaderNode.layout;
			if (layout == null) {
				throw new Error("FunctionOverloadingNode: FunctionNode must be a layout.");
			}
			var inputs = layout.inputs;
			if (params.length == inputs.length) {
				var score:Int = 0;
				for (i in 0...params.length) {
					var param = params[i];
					var input = inputs[i];
					if (param.getNodeType(builder) == input.type) {
						score++;
					} else {
						score = 0;
					}
				}
				if (score > candidateScore) {
					candidateFn = functionNode;
					candidateScore = score;
				}
			}
		}
		candidateFnCall = candidateFn.call(null, ...params);
		return candidateFnCall;
	}
}
var functionOverloadingNodeProxy:FunctionOverloadingNodeProxy = new FunctionOverloadingNodeProxy();
var overloadingFnProxy = (functionNodes:Array<Node>) => (...params:Array<Node>) => functionOverloadingNodeProxy.call(null, functionNodes, ...params);

export class FunctionOverloadingNode {
	public static function new(functionNodes:Array<Node> = [], ...parametersNodes:Array<Node>):FunctionOverloadingNode {
		return new FunctionOverloadingNode().call(null, functionNodes, ...parametersNodes);
	}
	private functionNodes:Array<Node>;
	private parametersNodes:Array<Node>;
	private _candidateFnCall:Node;
	public function call(functionNodes:Array<Node> = [], ...parametersNodes:Array<Node>):FunctionOverloadingNode {
		this.functionNodes = functionNodes;
		this.parametersNodes = parametersNodes;
		this._candidateFnCall = null;
		return this;
	}
	public function getNodeType():String {
		return this.functionNodes[0].shaderNode.layout.type;
	}
	public function setup(builder:Dynamic):Dynamic {
		var params = this.parametersNodes;
		var candidateFnCall = this._candidateFnCall;
		if (candidateFnCall == null) {
			var candidateFn:Node = null;
			var candidateScore:Int = -1;
			for (functionNode in this.functionNodes) {
				var shaderNode = functionNode.shaderNode;
				var layout = shaderNode.layout;
				if (layout == null) {
					throw new Error("FunctionOverloadingNode: FunctionNode must be a layout.");
				}
				var inputs = layout.inputs;
				if (params.length == inputs.length) {
					var score:Int = 0;
					for (i in 0...params.length) {
						var param = params[i];
						var input = inputs[i];
						if (param.getNodeType(builder) == input.type) {
							score++;
						} else {
							score = 0;
						}
					}
					if (score > candidateScore) {
						candidateFn = functionNode;
						candidateScore = score;
					}
				}
			}
			this._candidateFnCall = candidateFnCall = candidateFn.call(null, ...params);
		}
		return candidateFnCall;
	}
}

export var overloadingFn:Dynamic = overloadingFnProxy;

export var overloadingBaseFn:Dynamic = overloadingBaseFn;