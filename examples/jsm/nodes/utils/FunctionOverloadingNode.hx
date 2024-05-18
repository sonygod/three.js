package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class FunctionOverloadingNode extends Node {
    public var functionNodes:Array<Node>;
    public var parametersNodes:Array<Node>;
    private var _candidateFnCall:Node;

    public function new(?functionNodes:Array<Node> = [], ...parametersNodes:Array<Node>) {
        super();
        this.functionNodes = functionNodes;
        this.parametersNodes = parametersNodes;
        this._candidateFnCall = null;
    }

    public function getNodeType():String {
        return this.functionNodes[0].shaderNode.layout.type;
    }

    public function setup(builder:Dynamic):Node {
        var params:Array<Node> = this.parametersNodes;
        var candidateFnCall:Node = this._candidateFnCall;

        if (candidateFnCall == null) {
            var candidateFn:Node = null;
            var candidateScore:Int = -1;

            for (fn in this.functionNodes) {
                var shaderNode:ShaderNode = fn.shaderNode;
                var layout = shaderNode.layout;

                if (layout == null) {
                    throw new Error('FunctionOverloadingNode: FunctionNode must be a layout.');
                }

                var inputs:Array<Dynamic> = layout.inputs;

                if (params.length == inputs.length) {
                    var score:Int = 0;

                    for (i in 0...params.length) {
                        var param:Node = params[i];
                        var input:Dynamic = inputs[i];

                        if (param.getNodeType(builder) == input.type) {
                            score++;
                        } else {
                            score = 0;
                            break;
                        }
                    }

                    if (score > candidateScore) {
                        candidateFn = fn;
                        candidateScore = score;
                    }
                }
            }

            this._candidateFnCall = candidateFnCall = candidateFn != null ? candidateFn(shaderNode, params) : null;
        }

        return candidateFnCall;
    }
}

private function nodeProxy<T>(nodeClass:Class<T>):Class<T> {
    // Note: This is a simplified implementation of nodeProxy, you may need to adjust it according to your requirements
    return nodeClass;
}

private var overloadingBaseFn:Class<FunctionOverloadingNode> = nodeProxy(FunctionOverloadingNode);

public var overloadingFn:Array<Node>->Array<Node>->FunctionOverloadingNode = function(functionNodes:Array<Node>)(params:Array<Node>) {
    return overloadingBaseFn(functionNodes, params);
};

Node.addNodeClass('FunctionOverloadingNode', FunctionOverloadingNode);