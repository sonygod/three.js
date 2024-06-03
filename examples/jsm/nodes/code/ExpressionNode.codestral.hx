import Node from '../core/Node';
import {addNodeClass} from '../core/Node';
import {nodeProxy} from '../shadernode/ShaderNode';

class ExpressionNode extends Node {

    public var snippet:String;

    public function new(snippet:String = '', nodeType:String = 'void') {
        super(nodeType);
        this.snippet = snippet;
    }

    public function generate(builder:Dynamic, output:Dynamic):Dynamic {
        var type:String = this.getNodeType(builder);
        var snippet:String = this.snippet;

        if (type == 'void') {
            builder.addLineFlowCode(snippet);
        } else {
            return builder.format(`( ${snippet} )`, type, output);
        }

        return null;
    }
}

typedef ExpressionNodeClass = Class<ExpressionNode>;

var expression:Dynamic = nodeProxy(ExpressionNode);
addNodeClass('ExpressionNode', ExpressionNode);