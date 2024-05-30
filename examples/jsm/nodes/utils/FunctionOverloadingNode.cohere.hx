import Node from '../core/Node.hx';
import { nodeProxy } from '../shadernode/ShaderNode.hx';

class FunctionOverloadingNode extends Node {
    public functionNodes: Array<Node>;
    public parametersNodes: Array<Node>;
    private _candidateFnCall: Node;

    public function new(functionNodes: Array<Node> = [], ...parametersNodes: Array<Node>) {
        super();
        this.functionNodes = functionNodes;
        this.parametersNodes = parametersNodes;
        this._candidateFnCall = null;
    }

    public function getNodeType():Node {
        return this.functionNodes[0].shaderNode.layout.type;
    }

    public function setup(builder: Node): Node {
        var params = this.parametersNodes;
        var candidateFnCall = this._candidateFnCall;

        if (candidateFnCall == null) {
            var candidateFn: Node = null;
            var candidateScore = -1;

            for (functionNode in this.functionNodes) {
                var shaderNode = functionNode.shaderNode;
                var layout = shaderNode.layout;

                if (layout == null) {
                    throw "FunctionOverloadingNode: FunctionNode must have a layout.";
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

            this._candidateFnCall = candidateFnCall = candidateFn(...params);
        }

        return candidateFnCall;
    }
}

class FunctionOverloadingNodeExt {
    public static inline default(value: FunctionOverloadingNode) {
        return value;
    }

    public static inline overloadingBaseFn(value: FunctionOverloadingNode) {
        return nodeProxy(value);
    }

    public static inline overloadingFn(functionNodes: Array<Node>) {
        return function(...params: Array<Node>) {
            return overloadingBaseFn(functionNodes, ...params);
        }
    }
}