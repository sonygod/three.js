import three.nodes.core.Node;
import three.nodes.shadernode.ShaderNode;

class FunctionOverloadingNode extends Node {

    public var functionNodes: Array<Node>;
    public var parametersNodes: Array<Node>;
    private var _candidateFnCall: Node;

    public function new(functionNodes: Array<Node> = [], ...parametersNodes: Node[]) {
        super();

        this.functionNodes = functionNodes;
        this.parametersNodes = parametersNodes;

        this._candidateFnCall = null;
    }

    public function getNodeType(): String {
        return this.functionNodes[0].shaderNode.layout.type;
    }

    public function setup(builder: Builder): Node {
        var params = this.parametersNodes;

        var candidateFnCall = this._candidateFnCall;

        if (candidateFnCall == null) {
            var candidateFn: Node = null;
            var candidateScore: Int = -1;

            for (functionNode in this.functionNodes) {
                var shaderNode = functionNode.shaderNode;
                var layout = shaderNode.layout;

                if (layout == null) {
                    throw "FunctionOverloadingNode: FunctionNode must be a layout.";
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

            this._candidateFnCall = candidateFnCall = candidateFn.call(null, params);
        }

        return candidateFnCall;
    }
}

export default FunctionOverloadingNode;

const overloadingBaseFn = ShaderNode.nodeProxy(FunctionOverloadingNode);

public static function overloadingFn(functionNodes: Array<Node>): Function<Array<Node>, Node> {
    return function(params: Array<Node>): Node {
        return overloadingBaseFn(functionNodes, params);
    }
}

Node.addNodeClass("FunctionOverloadingNode", typeof(FunctionOverloadingNode));