package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.shadernode.ShaderNode.NodeProxy;

class FunctionOverloadingNode extends Node
{
    public var functionNodes:Array<Node>;
    public var parametersNodes:Array<Node>;
    private var _candidateFnCall:Node;

    public function new(?functionNodes:Array<Node> = [], ?parametersNodes:Array<Node> = [])
    {
        super();
        this.functionNodes = functionNodes;
        this.parametersNodes = parametersNodes;
        this._candidateFnCall = null;
    }

    public function getNodeType():String
    {
        return this.functionNodes[0].shaderNode.layout.type;
    }

    public function setup(builder:Dynamic):Node
    {
        var params:Array<Node> = this.parametersNodes;
        var candidateFnCall:Node = this._candidateFnCall;

        if (candidateFnCall == null)
        {
            var candidateFn:Node = null;
            var candidateScore:Int = -1;

            for (functionNode in this.functionNodes)
            {
                var shaderNode:ShaderNode = functionNode.shaderNode;
                var layout:Layout = shaderNode.layout;

                if (layout == null)
                {
                    throw new Error('FunctionOverloadingNode: FunctionNode must be a layout.');
                }

                var inputs:Array<Input> = layout.inputs;

                if (params.length == inputs.length)
                {
                    var score:Int = 0;

                    for (i in 0...params.length)
                    {
                        var param:Node = params[i];
                        var input:Input = inputs[i];

                        if (param.getNodeType(builder) == input.type)
                        {
                            score++;
                        }
                        else
                        {
                            score = 0;
                        }
                    }

                    if (score > candidateScore)
                    {
                        candidateFn = functionNode;
                        candidateScore = score;
                    }
                }
            }

            this._candidateFnCall = candidateFnCall = candidateFn != null ? candidateFn.setup(builder, params) : null;
        }

        return candidateFnCall;
    }
}

typedef Layout = {
    type:String,
    inputs:Array<Input>
}

typedef Input = {
    type:String
}

class NodeProxy
{
    public static function create<T>(nodeClass:Class<T>):T
    {
        return cast new nodeClass();
    }
}

var overloadingBaseFn:NodeProxy = NodeProxy.create(FunctionOverloadingNode);
var overloadingFn = function(?functionNodes:Array<Node>) return function(?params:Array<Node>) return overloadingBaseFn(functionNodes, params);

Node.addNodeClass('FunctionOverloadingNode', FunctionOverloadingNode);