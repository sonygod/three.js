package three.js.examples.jsm.nodes.code;

import three.core.TempNode;
import three.core.Node;
import three.shadernode.ShaderNode;

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

    public function getNodeType(builder:Dynamic):Dynamic {
        return this.functionNode.getNodeType(builder);
    }

    public function generate(builder:Dynamic):String {
        var params:Array<Dynamic> = [];
        var functionNode:Node = this.functionNode;
        var inputs:Array<Dynamic> = functionNode.getInputs(builder);
        var parameters:Dynamic = this.parameters;

        if (Std.is(parameters, Array)) {
            for (i in 0...parameters.length) {
                var inputNode:Dynamic = inputs[i];
                var node:Dynamic = parameters[i];
                params.push(node.build(builder, inputNode.type));
            }
        } else {
            for (inputNode in inputs) {
                var node:Dynamic = parameters[inputNode.name];
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

@:keep
function call(func:Dynamic, params:Rest<Dynamic>):ShaderNode {
    params = if (params.length > 1 || (params[0] != null && params[0].isNode == true)) nodeArray(params) else nodeObjects(params[0]);
    return nodeObject(new FunctionCallNode(nodeObject(func), params));
}

@:keep
addNodeElement('call', call);

@:keep
addNodeClass('FunctionCallNode', FunctionCallNode);