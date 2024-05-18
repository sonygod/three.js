package three.js.examples.nodes.display;

import three.js.core.TempNode;
import three.js.math.MathNode;
import three.js.shadernode.ShaderNode;

class BlendModeNode extends TempNode {
    public static inline var BURN:String = 'burn';
    public static inline var DODGE:String = 'dodge';
    public static inline var SCREEN:String = 'screen';
    public static inline var OVERLAY:String = 'overlay';

    public var blendMode:String;
    public var baseNode:TempNode;
    public var blendNode:TempNode;

    public function new(blendMode:String, baseNode:TempNode, blendNode:TempNode) {
        super();
        this.blendMode = blendMode;
        this.baseNode = baseNode;
        this.blendNode = blendNode;
    }

    override public function setup():TempNode {
        var params = { base: baseNode, blend: blendNode };
        var outputNode:TempNode = null;

        switch (blendMode) {
            case BURN:
                outputNode = new BurnNode(params);
            case DODGE:
                outputNode = new DodgeNode(params);
            case SCREEN:
                outputNode = new ScreenNode(params);
            case OVERLAY:
                outputNode = new OverlayNode(params);
        }

        return outputNode;
    }
}

class BurnNode extends ShaderNode {
    public function new(params:Dynamic) {
        super({
            name: 'burnColor',
            type: 'vec3',
            inputs: [
                { name: 'base', type: 'vec3' },
                { name: 'blend', type: 'vec3' }
            ]
        });

        var fn = function(c:String) {
            return blend[c].lessThan(MathNode.EPSILON) ? blend[c] : base[c].oneMinus().div(blend[c]).oneMinus().max(0);
        };

        outputs.push(new Vec3(fn('x'), fn('y'), fn('z')));
    }
}

class DodgeNode extends ShaderNode {
    public function new(params:Dynamic) {
        super({
            name: 'dodgeColor',
            type: 'vec3',
            inputs: [
                { name: 'base', type: 'vec3' },
                { name: 'blend', type: 'vec3' }
            ]
        });

        var fn = function(c:String) {
            return blend[c].equal(1.0) ? blend[c] : base[c].div(blend[c].oneMinus()).max(0);
        };

        outputs.push(new Vec3(fn('x'), fn('y'), fn('z')));
    }
}

class ScreenNode extends ShaderNode {
    public function new(params:Dynamic) {
        super({
            name: 'screenColor',
            type: 'vec3',
            inputs: [
                { name: 'base', type: 'vec3' },
                { name: 'blend', type: 'vec3' }
            ]
        });

        var fn = function(c:String) {
            return base[c].oneMinus().mul(blend[c].oneMinus()).oneMinus();
        };

        outputs.push(new Vec3(fn('x'), fn('y'), fn('z')));
    }
}

class OverlayNode extends ShaderNode {
    public function new(params:Dynamic) {
        super({
            name: 'overlayColor',
            type: 'vec3',
            inputs: [
                { name: 'base', type: 'vec3' },
                { name: 'blend', type: 'vec3' }
            ]
        });

        var fn = function(c:String) {
            return base[c].lessThan(0.5) ? base[c].mul(blend[c], 2.0) : base[c].oneMinus().mul(blend[c].oneMinus()).oneMinus();
        };

        outputs.push(new Vec3(fn('x'), fn('y'), fn('z')));
    }
}

// Proxy nodes
var burn = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.BURN);
var dodge = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.DODGE);
var overlay = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.OVERLAY);
var screen = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.SCREEN);

ShaderNode.addNodeElement('burn', burn);
ShaderNode.addNodeElement('dodge', dodge);
ShaderNode.addNodeElement('overlay', overlay);
ShaderNode.addNodeElement('screen', screen);

ShaderNode.addNodeClass('BlendModeNode', BlendModeNode);