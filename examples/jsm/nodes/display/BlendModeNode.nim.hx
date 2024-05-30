import TempNode from '../core/TempNode.js';
import { /*mix, step,*/ EPSILON } from '../math/MathNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, tslFn, nodeProxy, vec3 } from '../shadernode/ShaderNode.js';

class BurnNode {
    public static fn(c:String):Dynamic {
        return blend[c].lessThan(EPSILON).cond(blend[c], base[c].oneMinus().div(blend[c]).oneMinus().max(0));
    }

    public static main():Vec3 {
        return vec3(fn('x'), fn('y'), fn('z'));
    }
}

BurnNode.setLayout({
    name: 'burnColor',
    type: 'vec3',
    inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
    ]
});

class DodgeNode {
    public static fn(c:String):Dynamic {
        return blend[c].equal(1.0).cond(blend[c], base[c].div(blend[c].oneMinus()).max(0));
    }

    public static main():Vec3 {
        return vec3(fn('x'), fn('y'), fn('z'));
    }
}

DodgeNode.setLayout({
    name: 'dodgeColor',
    type: 'vec3',
    inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
    ]
});

class ScreenNode {
    public static fn(c:String):Dynamic {
        return base[c].oneMinus().mul(blend[c].oneMinus()).oneMinus();
    }

    public static main():Vec3 {
        return vec3(fn('x'), fn('y'), fn('z'));
    }
}

ScreenNode.setLayout({
    name: 'screenColor',
    type: 'vec3',
    inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
    ]
});

class OverlayNode {
    public static fn(c:String):Dynamic {
        return base[c].lessThan(0.5).cond(base[c].mul(blend[c], 2.0), base[c].oneMinus().mul(blend[c].oneMinus()).oneMinus());
    }

    public static main():Vec3 {
        return vec3(fn('x'), fn('y'), fn('z'));
    }
}

OverlayNode.setLayout({
    name: 'overlayColor',
    type: 'vec3',
    inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
    ]
});

class BlendModeNode extends TempNode {

    public var blendMode:String;
    public var baseNode:TempNode;
    public var blendNode:TempNode;

    public function new(blendMode:String, baseNode:TempNode, blendNode:TempNode) {
        super();
        this.blendMode = blendMode;
        this.baseNode = baseNode;
        this.blendNode = blendNode;
    }

    public function setup():Dynamic {
        var params = { base: baseNode, blend: blendNode };
        var outputNode:Dynamic;

        switch (blendMode) {
            case BlendModeNode.BURN:
                outputNode = BurnNode.main(params);
                break;
            case BlendModeNode.DODGE:
                outputNode = DodgeNode.main(params);
                break;
            case BlendModeNode.SCREEN:
                outputNode = ScreenNode.main(params);
                break;
            case BlendModeNode.OVERLAY:
                outputNode = OverlayNode.main(params);
                break;
        }

        return outputNode;
    }
}

BlendModeNode.BURN = 'burn';
BlendModeNode.DODGE = 'dodge';
BlendModeNode.SCREEN = 'screen';
BlendModeNode.OVERLAY = 'overlay';

addNodeClass('BlendModeNode', BlendModeNode);

var burn = nodeProxy(BlendModeNode, BlendModeNode.BURN);
var dodge = nodeProxy(BlendModeNode, BlendModeNode.DODGE);
var overlay = nodeProxy(BlendModeNode, BlendModeNode.OVERLAY);
var screen = nodeProxy(BlendModeNode, BlendModeNode.SCREEN);

addNodeElement('burn', burn);
addNodeElement('dodge', dodge);
addNodeElement('overlay', overlay);
addNodeElement('screen', screen);