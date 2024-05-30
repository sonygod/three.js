import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.math.MathNode;
import three.examples.jsm.nodes.core.Node;
import three.examples.jsm.nodes.shadernode.ShaderNode;

class BlendModeNode extends TempNode {

    public static var BURN:String = 'burn';
    public static var DODGE:String = 'dodge';
    public static var SCREEN:String = 'screen';
    public static var OVERLAY:String = 'overlay';

    public var blendMode:String;
    public var baseNode:ShaderNode;
    public var blendNode:ShaderNode;

    public function new(blendMode:String, baseNode:ShaderNode, blendNode:ShaderNode) {
        super();
        this.blendMode = blendMode;
        this.baseNode = baseNode;
        this.blendNode = blendNode;
    }

    public function setup():ShaderNode {
        var params = {base: baseNode, blend: blendNode};
        var outputNode:ShaderNode = null;

        switch (blendMode) {
            case BURN:
                outputNode = BlendModeNode.burn(params);
                break;
            case DODGE:
                outputNode = BlendModeNode.dodge(params);
                break;
            case SCREEN:
                outputNode = BlendModeNode.screen(params);
                break;
            case OVERLAY:
                outputNode = BlendModeNode.overlay(params);
                break;
        }

        return outputNode;
    }

    public static function burn(params:{base:ShaderNode, blend:ShaderNode}):ShaderNode {
        // Implementation of burn function
    }

    public static function dodge(params:{base:ShaderNode, blend:ShaderNode}):ShaderNode {
        // Implementation of dodge function
    }

    public static function screen(params:{base:ShaderNode, blend:ShaderNode}):ShaderNode {
        // Implementation of screen function
    }

    public static function overlay(params:{base:ShaderNode, blend:ShaderNode}):ShaderNode {
        // Implementation of overlay function
    }
}

class Main {
    static function main() {
        Node.addNodeElement('burn', BlendModeNode.burn);
        Node.addNodeElement('dodge', BlendModeNode.dodge);
        Node.addNodeElement('overlay', BlendModeNode.overlay);
        Node.addNodeElement('screen', BlendModeNode.screen);

        Node.addNodeClass('BlendModeNode', BlendModeNode);
    }
}