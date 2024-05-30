package three.js.examples.jsm.nodes.procedural;

import three.js.core.TempNode;
import three.js.accessors.UVNode;
import three.js.shadernode.ShaderNode;

class CheckerNode extends TempNode {
  var uvNode:UVNode;

  public function new(?uvNode:UVNode) {
    super('float');
    this.uvNode = uvNode != null ? uvNode : UVNode.create();
  }

  override function setup():ShaderNode {
    var checkerShaderNode = ShaderNode.tslFn(function(inputs) {
      var uv = inputs.uv.mul(2.0);
      var cx = Math.floor(uv.x);
      var cy = Math.floor(uv.y);
      var result = (cx + cy) % 2.0;
      return Math.sign(result);
    });
    return checkerShaderNode({'uv': this.uvNode});
  }
}

// Export the CheckerNode class
@:keep
@:native('CheckerNode')
class CheckerNodeNative extends CheckerNode {}

// Export the checker node proxy
@:keep
@:native('checker')
var checker:CheckerNodeNative;

// Register the node element
ShaderNode.addNodeElement('checker', checker);

// Register the node class
ShaderNode.addNodeClass('CheckerNode', CheckerNodeNative);