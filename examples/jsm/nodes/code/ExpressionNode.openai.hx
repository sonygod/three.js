package three.js.examples.jm.nodes.code;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class ExpressionNode extends Node {
    
    public var snippet:String;
    
    public function new(snippet:String = '', nodeType:String = 'void') {
        super(nodeType);
        this.snippet = snippet;
    }
    
    override public function generate(builder:Dynamic, output:Dynamic):Void {
        var type:String = getNodeType(builder);
        var snippet:String = this.snippet;
        
        if (type == 'void') {
            builder.addLineFlowCode(snippet);
        } else {
            builder.format(' (${snippet} )', type, output);
        }
    }
}

// Not sure how to translate the nodeProxy function, as it's not a standard Haxe function
// You might need to implement it manually or use a similar function in Haxe
// extern class nodeProxy {
//     public static function proxy<T>(cl:Class<T>):T {
//         // Implement the proxy logic here
//         throw "Not implemented";
//     }
// }

// Export the ExpressionNode class
 Lana.export(default, ExpressionNode);

// Export the expression proxy
 Lana.export('expression', nodeProxy(ExpressionNode));

// Add the node class to the node registry
Node.addNodeClass('ExpressionNode', ExpressionNode);