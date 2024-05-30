import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class FunctionOverloadingNode extends Node {

	public functionNodes:Array<Dynamic>;
	public parametersNodes:Array<Dynamic>;
	private var _candidateFnCall:Dynamic;

	public function new(functionNodes:Array<Dynamic> = [], parametersNodes:Array<Dynamic>) {
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
			var candidateFn:Dynamic = null;
			var candidateScore = -1;
			for (functionNode in this.functionNodes) {
				var shaderNode = functionNode.shaderNode;
				var layout = shaderNode.layout;
				if (layout == null) {
					throw 'FunctionOverloadingNode: FunctionNode must be a layout.';
				}
				var inputs = layout.inputs;
				if (params.length == inputs.length) {
					var score = 0;
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
			this._candidateFnCall = candidateFnCall = candidateFn(params);
		}
		return candidateFnCall;
	}

}

static function overloadingBaseFn(nodeProxy:Dynamic):Dynamic {
	return nodeProxy(FunctionOverloadingNode);
}

static function overloadingFn(functionNodes:Array<Dynamic>):Dynamic->Dynamic {
	return (params:Array<Dynamic>) -> overloadingBaseFn(functionNodes, params);
}

Node.addNodeClass('FunctionOverloadingNode', FunctionOverloadingNode);