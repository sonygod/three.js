import haxe.ds.StringMap;

import TempNode from '../core/TempNode.hx';
import { EPSILON } from '../math/MathNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy, vec3 } from '../shadernode/ShaderNode.hx';

class BurnNode {
  public static setLayout() {
    return {
      name: 'burnColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    };
  }

  public constructor(base: any, blend: any) {
    this.base = base;
    this.blend = blend;
  }

  public fn(c: string) {
    return vec3(blend[c].lessThan(EPSILON).choose(blend[c], base[c].subtract(1.0).divide(blend[c]).subtract(1.0).max(0.0)));
  }

  public call() {
    return vec3(this.fn('x'), this.fn('y'), this.fn('z'));
  }
}

class DodgeNode {
  public static setLayout() {
    return {
      name: 'dodgeColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    };
  }

  public constructor(base: any, blend: any) {
    this.base = base;
    this.blend = blend;
  }

  public fn(c: string) {
    return vec3(blend[c].equal(1.0).choose(blend[c], base[c].divide(blend[c].subtract(1.0)).max(0.0)));
  }

  public call() {
    return vec3(this.fn('x'), this.fn('y'), this.fn('z'));
  }
}

class ScreenNode {
  public static setLayout() {
    return {
      name: 'screenColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    };
  }

  public constructor(base: any, blend: any) {
    this.base = base;
    this.blend = blend;
  }

  public fn(c: string) {
    return vec3(base[c].subtract(1.0).multiply(blend[c].subtract(1.0)).subtract(1.0));
  }

  public call() {
    return vec3(this.fn('x'), this.fn('y'), this.fn('z'));
  }
}

class OverlayNode {
  public static setLayout() {
    return {
      name: 'overlayColor',
      type: 'vec3',
      inputs: [
        { name: 'base', type: 'vec3' },
        { name: 'blend', type: 'vec3' }
      ]
    };
  }

  public constructor(base: any, blend: any) {
    this.base = base;
    this.blend = blend;
  }

  public fn(c: string) {
    return vec3(base[c].lessThan(0.5).choose(base[c].multiply(2.0).multiply(blend[c]), base[c].subtract(1.0).multiply(blend[c].subtract(1.0)).subtract(1.0)));
  }

  public call() {
    return vec3(this.fn('x'), this.fn('y'), this.fn('z'));
  }
}

class BlendModeNode extends TempNode {
  public static BURN = 'burn';
  public static DODGE = 'dodge';
  public static SCREEN = 'screen';
  public static OVERLAY = 'overlay';

  public blendMode: string;
  public baseNode: any;
  public blendNode: any;

  public constructor(blendMode: string, baseNode: any, blendNode: any) {
    super();
    this.blendMode = blendMode;
    this.baseNode = baseNode;
    this.blendNode = blendNode;
  }

  public setup() {
    var params = { base: this.baseNode, blend: this.blendNode };

    if (this.blendMode == BlendModeNode.BURN) {
      return new BurnNode(params).call();
    } else if (this.blendMode == BlendModeNode.DODGE) {
      return new DodgeNode(params).call();
    } else if (this.blendMode == BlendModeNode.SCREEN) {
      return new ScreenNode(params).call();
    } else if (this.blendMode == BlendModeNode.OVERLAY) {
      return new OverlayNode(params).call();
    }

    return null;
  }
}

var blendModeNodeMap = new StringMap();

function createBlendModeNode(blendMode: string) {
  return function($base: any, $blend: any) {
    return new BlendModeNode(blendMode, $base, $blend);
  };
}

blendModeNodeMap.set(BlendModeNode.BURN, createBlendModeNode(BlendModeNode.BURN));
blendModeNodeMap.set(BlendModeNode.DODGE, createBlendModeNode(BlendModeNode.DODGE));
blendModeNodeMap.set(BlendModeNode.SCREEN, createBlendModeNode(BlendModeNode.SCREEN));
blendModeNodeMap.set(BlendModeNode.OVERLAY, createBlendModeNode(BlendModeNode.OVERLAY));

addNodeClass('BlendModeNode', BlendModeNode);

addNodeElement('burn', nodeProxy(BlendModeNode, BlendModeNode.BURN));
addNodeElement('dodge', nodeProxy(BlendModeNode, BlendModeNode.DODGE));
addNodeElement('overlay', nodeProxy(BlendModeNode, BlendModeNode.OVERLAY));
addNodeElement('screen', nodeProxy(BlendModeNode, BlendModeNode.SCREEN));

export default BlendModeNode;

export function burn($base: any, $blend: any) {
  return blendModeNodeMap.get(BlendModeNode.BURN).call($base, $blend);
}

export function dodge($base: any, $blend: any) {
  return blendModeNodeMap.get(BlendModeNode.DODGE).call($base, $blend);
}

export function overlay($base: any, $blend: any) {
  return blendModeNodeMap.get(BlendModeNode.OVERLAY).call($base, $blend);
}

export function screen($base: any, $blend: any) {
  return blendModeNodeMap.get(BlendModeNode.SCREEN).call($base, $blend);
}