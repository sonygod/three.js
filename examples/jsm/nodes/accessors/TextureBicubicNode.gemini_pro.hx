import TempNode from "../core/TempNode";
import Node from "../core/Node";
import OperatorNode from "../math/OperatorNode";
import MathNode from "../math/MathNode";
import ShaderNode from "../shadernode/ShaderNode";

class TextureBicubicNode extends TempNode {
  public textureNode:Node;
  public blurNode:Node;

  public function new(textureNode:Node, blurNode:Node = ShaderNode.float(3)) {
    super("vec4");
    this.textureNode = textureNode;
    this.blurNode = blurNode;
  }

  override public function setup():Node {
    return textureBicubicMethod(this.textureNode, this.blurNode);
  }
}

var bC:Float = 1.0 / 6.0;

var w0 = (a:Node) -> Node {
  return OperatorNode.mul(bC, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.sub(OperatorNode.add(OperatorNode.negate(a), 3.0), 3.0)).sub(3.0)).add(1.0));
};

var w1 = (a:Node) -> Node {
  return OperatorNode.mul(bC, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.sub(OperatorNode.mul(3.0, a), 6.0)).add(4.0)));
};

var w2 = (a:Node) -> Node {
  return OperatorNode.mul(bC, OperatorNode.mul(a, OperatorNode.mul(a, OperatorNode.add(OperatorNode.mul(-3.0, a), 3.0)).add(3.0)).add(1.0));
};

var w3 = (a:Node) -> Node {
  return OperatorNode.mul(bC, MathNode.pow(a, 3));
};

var g0 = (a:Node) -> Node {
  return OperatorNode.add(w0(a), w1(a));
};

var g1 = (a:Node) -> Node {
  return OperatorNode.add(w2(a), w3(a));
};

// h0 and h1 are the two offset functions
var h0 = (a:Node) -> Node {
  return OperatorNode.add(-1.0, OperatorNode.div(w1(a), OperatorNode.add(w0(a), w1(a))));
};

var h1 = (a:Node) -> Node {
  return OperatorNode.add(1.0, OperatorNode.div(w3(a), OperatorNode.add(w2(a), w3(a))));
};

var bicubic = (textureNode:Node, texelSize:Node, lod:Node) -> Node {
  var uv = textureNode.uvNode;
  var uvScaled = OperatorNode.add(OperatorNode.mul(uv, ShaderNode.vec2(texelSize.zw)), 0.5);

  var iuv = MathNode.floor(uvScaled);
  var fuv = MathNode.fract(uvScaled);

  var g0x = g0(fuv.x);
  var g1x = g1(fuv.x);
  var h0x = h0(fuv.x);
  var h1x = h1(fuv.x);
  var h0y = h0(fuv.y);
  var h1y = h1(fuv.y);

  var p0 = OperatorNode.mul(OperatorNode.sub(ShaderNode.vec2(OperatorNode.add(iuv.x, h0x), OperatorNode.add(iuv.y, h0y)), 0.5), ShaderNode.vec2(texelSize.xy));
  var p1 = OperatorNode.mul(OperatorNode.sub(ShaderNode.vec2(OperatorNode.add(iuv.x, h1x), OperatorNode.add(iuv.y, h0y)), 0.5), ShaderNode.vec2(texelSize.xy));
  var p2 = OperatorNode.mul(OperatorNode.sub(ShaderNode.vec2(OperatorNode.add(iuv.x, h0x), OperatorNode.add(iuv.y, h1y)), 0.5), ShaderNode.vec2(texelSize.xy));
  var p3 = OperatorNode.mul(OperatorNode.sub(ShaderNode.vec2(OperatorNode.add(iuv.x, h1x), OperatorNode.add(iuv.y, h1y)), 0.5), ShaderNode.vec2(texelSize.xy));

  var a = OperatorNode.mul(g0(fuv.y), OperatorNode.add(OperatorNode.mul(g0x, textureNode.uv(p0).level(lod)), OperatorNode.mul(g1x, textureNode.uv(p1).level(lod))));
  var b = OperatorNode.mul(g1(fuv.y), OperatorNode.add(OperatorNode.mul(g0x, textureNode.uv(p2).level(lod)), OperatorNode.mul(g1x, textureNode.uv(p3).level(lod))));

  return OperatorNode.add(a, b);
};

var textureBicubicMethod = (textureNode:Node, lodNode:Node) -> Node {
  var fLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(lodNode)));
  var cLodSize = ShaderNode.vec2(textureNode.size(ShaderNode.int(OperatorNode.add(lodNode, 1.0))));
  var fLodSizeInv = OperatorNode.div(1.0, fLodSize);
  var cLodSizeInv = OperatorNode.div(1.0, cLodSize);
  var fSample = bicubic(textureNode, ShaderNode.vec4(fLodSizeInv, fLodSize), MathNode.floor(lodNode));
  var cSample = bicubic(textureNode, ShaderNode.vec4(cLodSizeInv, cLodSize), MathNode.ceil(lodNode));

  return MathNode.fract(lodNode).mix(fSample, cSample);
};

export var textureBicubic = (textureNode:Node, blurNode:Node = ShaderNode.float(3)) -> TextureBicubicNode {
  return new TextureBicubicNode(textureNode, blurNode);
};

Node.addNodeClass("TextureBicubicNode", TextureBicubicNode);