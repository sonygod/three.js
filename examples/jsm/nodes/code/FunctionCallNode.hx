package three.js.examples.jsm.nodes.code;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class FunctionCallNode extends TempNode {
    public var functionNode:Node;
    public var parameters:Dynamic;

    public function new(?functionNode:Node, ?parameters:Dynamic) {
        super();
        this.functionNode = functionNode;
        this.parameters = parameters;
    }

    public function setParameters(parameters:Dynamic):FunctionCallNode {
        this.parameters = parameters;
        return this;
    }

    public function getParameters():Dynamic {
        return this.parameters;
    }

    public function getNodeType(builder:Dynamic):String {
        return this.functionNode.getNodeType(builder);
    }

    public function generate(builder:Dynamic):String {
        var params:Array<String> = [];
        var functionNode:Node = this.functionNode;
        var inputs:Array<Node> = functionNode.getInputs(builder);
        var parameters:Dynamic = this.parameters;

        if (Std.isOfType(parameters, Array)) {
            for (i in 0...parameters.length) {
                var inputNode:Node = inputs[i];
                var node:Node = parameters[i];
                params.push(node.build(builder, inputNode.type));
            }
        } else {
            for (inputNode in inputs) {
                var node:Node = parameters[inputNode.name];
                if (node != null) {
                    params.push(node.build(builder, inputNode.type));
                } else {
                    throw new Error('FunctionCallNode: Input \'${inputNode.name}\' not found in FunctionNode.');
                }
            }
        }

        var functionName:String = functionNode.build(builder, 'property');
        return '${functionName}(${params.join(', ')})';
    }
}

class FunctionCall {
    public static function call(func:Node, params:Array<Dynamic>):Node {
        params = params.length > 1 || (params[0] != null && params[0].isNode == true) ? nodeArray(params) : nodeObjects(params[0]);
        return nodeObject(new FunctionCallNode(nodeObject(func), params));
    }
}

ShaderNode.addNodeElement('call', FunctionCall.call);
Node.addNodeClass('FunctionCallNode', FunctionCallNode);