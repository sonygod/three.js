package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.js.math.MathNode;

using three.js.shader.node.ShaderNode;

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

  public function setup():TempNode {
    var params = { base: baseNode, blend: blendNode };
    var outputNode:TempNode = null;

    switch (blendMode) {
      case BlendModeNode.BURN:
        outputNode = BurnNode(params);
      case BlendModeNode.DODGE:
        outputNode = DodgeNode(params);
      case BlendModeNode.SCREEN:
        outputNode = ScreenNode(params);
      case BlendModeNode.OVERLAY:
        outputNode = OverlayNode(params);
    }

    return outputNode;
  }
}

class BurnNode extends ShaderNode {
  public function new(params:{base:TempNode, blend:TempNode}) {
    super();
    var fn = function(c:String) {
      return blend[c].lessThan(MathNode.EPSILON).cond(blend[c], base[c].oneMinus().div(blend[c]).oneMinus().max(0));
    };
    setLayout({
      name: 'burnColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    });
    set Vec3(fn('x'), fn('y'), fn('z'));
  }
}

class DodgeNode extends ShaderNode {
  public function new(params:{base:TempNode, blend:TempNode}) {
    super();
    var fn = function(c:String) {
      return blend[c].equal(1.0).cond(blend[c], base[c].div(blend[c].oneMinus()).max(0));
    };
    setLayout({
      name: 'dodgeColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    });
    set Vec3(fn('x'), fn('y'), fn('z'));
  }
}

class ScreenNode extends ShaderNode {
  public function new(params:{base:TempNode, blend:TempNode}) {
    super();
    var fn = function(c:String) {
      return base[c].oneMinus().mul(blend[c].oneMinus()).oneMinus();
    };
    setLayout({
      name: 'screenColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    });
    set Vec3(fn('x'), fn('y'), fn('z'));
  }
}

class OverlayNode extends ShaderNode {
  public function new(params:{base:TempNode, blend:TempNode}) {
    super();
    var fn = function(c:String) {
      return base[c].lessThan(0.5).cond(base[c].mul(blend[c], 2.0), base[c].oneMinus().mul(blend[c].oneMinus()).oneMinus());
    };
    setLayout({
      name: 'overlayColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    });
    set Vec3(fn('x'), fn('y'), fn('z'));
  }
}

class BlendModeNode {
  public static inline var BURN:String = 'burn';
  public static inline var DODGE:String = 'dodge';
  public static inline var SCREEN:String = 'screen';
  public static inline var OVERLAY:String = 'overlay';
}

var burn = nodeProxy(BlendModeNode, BlendModeNode.BURN);
var dodge = nodeProxy(BlendModeNode, BlendModeNode.DODGE);
var overlay = nodeProxy(BlendModeNode, BlendModeNode.OVERLAY);
var screen = nodeProxy(BlendModeNode, BlendModeNode.SCREEN);

addNodeElement('burn', burn);
addNodeElement('dodge', dodge);
addNodeElement('overlay', overlay);
addNodeElement('screen', screen);

addNodeClass('BlendModeNode', BlendModeNode);