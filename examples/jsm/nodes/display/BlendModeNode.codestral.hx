import TempNode from '../core/TempNode';
import MathNode from '../math/MathNode';
import Node from '../core/Node';
import ShaderNode from '../shadernode/ShaderNode';

class BlendModeNode extends TempNode {
    public var blendMode: String;
    public var baseNode: ShaderNode;
    public var blendNode: ShaderNode;

    public function new(blendMode: String, baseNode: ShaderNode, blendNode: ShaderNode) {
        super();
        this.blendMode = blendMode;
        this.baseNode = baseNode;
        this.blendNode = blendNode;
    }

    public function setup(): ShaderNode {
        var params = { base: this.baseNode, blend: this.blendNode };

        switch (this.blendMode) {
            case BlendModeNode.BURN:
                return BurnNode(params);
            case BlendModeNode.DODGE:
                return DodgeNode(params);
            case BlendModeNode.SCREEN:
                return ScreenNode(params);
            case BlendModeNode.OVERLAY:
                return OverlayNode(params);
            default:
                return null;
        }
    }
}

@:build(tslFn)
class BurnNode {
    public function new(params: Dynamic) {
        // function body
    }
}

@:build(tslFn)
class DodgeNode {
    public function new(params: Dynamic) {
        // function body
    }
}

@:build(tslFn)
class ScreenNode {
    public function new(params: Dynamic) {
        // function body
    }
}

@:build(tslFn)
class OverlayNode {
    public function new(params: Dynamic) {
        // function body
    }
}

class BlendModeNode {
    public static var BURN: String = "burn";
    public static var DODGE: String = "dodge";
    public static var SCREEN: String = "screen";
    public static var OVERLAY: String = "overlay";
}

ShaderNode.addNodeElement("burn", ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.BURN));
ShaderNode.addNodeElement("dodge", ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.DODGE));
ShaderNode.addNodeElement("overlay", ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.OVERLAY));
ShaderNode.addNodeElement("screen", ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.SCREEN));

Node.addNodeClass("BlendModeNode", BlendModeNode);