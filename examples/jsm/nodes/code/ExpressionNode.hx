package three.js.examples.jsm.nodes.code;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class ExpressionNode extends Node
{
    public var snippet:String;

    public function new(snippet:String = '', nodeType:String = 'void')
    {
        super(nodeType);
        this.snippet = snippet;
    }

    public function generate(builder:Dynamic, output:Dynamic):String
    {
        var type:String = getNodeCode(builder);
        var snippet:String = this.snippet;

        if (type == 'void')
        {
            builder.addLineFlowCode(snippet);
            return '';
        }
        else
        {
            return builder.format('($snippet)', type, output);
        }
    }
}

@:keep
@:native('expression')
private static var _expression:Dynamic = nodeProxy(ExpressionNode);

@:keep
private static function addNodeClass():Void
{
    Node.addNodeClass('ExpressionNode', ExpressionNode);
}