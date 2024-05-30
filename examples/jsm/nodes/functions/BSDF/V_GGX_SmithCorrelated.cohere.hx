import js.Math;

@:shim("Math.pow({this}, {0})")
private inline function pow(x: Float, y: Float): Float {
  return Math.pow(x, y);
}

@:shim("Math.sqrt({0})")
private inline function sqrt(x: Float): Float {
  return Math.sqrt(x);
}

class V_GGX_SmithCorrelated {
  public function new(alpha: Float, dotNL: Float, dotNV: Float): Float {
    var a2 = pow(alpha, 2.0);
    var gv = dotNL * sqrt(a2 + pow(dotNV, 2.0) * (1.0 - a2));
    var gl = dotNV * sqrt(a2 + pow(dotNL, 2.0) * (1.0 - a2));
    return 0.5 / max(gv + gl, EPSILON);
  }
}

alias V_GGX_SmithCorrelated->new this;

const Float EPSILON = 1e-6;

class ShaderNode {
  public var layout: { name: String, type: String, inputs: Array<Map<String, String>> };

  public function new() {
    layout = {
      name: 'V_GGX_SmithCorrelated',
      type: 'float',
      inputs: [
        { name: 'alpha', type: 'float' },
        { name: 'dotNL', type: 'float' },
        { name: 'dotNV', type: 'float' }
      ]
    };
  }

  public function setLayout(value: { name: String, type: String, inputs: Array<Map<String, String>> }) {
    layout = value;
  }
}

class V_GGX_SmithCorrelatedNode extends ShaderNode {
  public function new() {
    super();
  }

  public function tslFn(): V_GGX_SmithCorrelated {
    return V_GGX_SmithCorrelated;
  }
}

@:shim("({setLayout: { $0 }}})")
private function createShaderNode(layout: { name: String, type: String, inputs: Array<Map<String, String>> }): V_GGX_SmithCorrelatedNode {
  var node = new V_GGX_SmithCorrelatedNode();
  node.setLayout(layout);
  return node;
}

@:export(default)
var V_GGX_SmithCorrelated = createShaderNode({
  name: 'V_GGX_SmithCorrelated',
  type: 'float',
  inputs: [
    { name: 'alpha', type: 'float' },
    { name: 'dotNL', type: 'float' },
    { name: 'dotNV', type: 'float' }
  ]
});