import TempNode from "../core/TempNode";
import MathNode from "../math/MathNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import LinearSRGBColorSpace from "three";
import SRGBColorSpace from "three";

class ColorSpaceNode extends TempNode {
  public method: String;
  public node: Node;

  public function new(method: String, node: Node) {
    super("vec4");
    this.method = method;
    this.node = node;
  }

  override public function setup(): Node {
    var method = this.method;
    var node = this.node;

    if (method == ColorSpaceNode.LINEAR_TO_LINEAR) {
      return node;
    }

    return Methods[method]({value: node});
  }
}

ColorSpaceNode.LINEAR_TO_LINEAR = "LinearToLinear";
ColorSpaceNode.LINEAR_TO_sRGB = "LinearTosRGB";
ColorSpaceNode.sRGB_TO_LINEAR = "sRGBToLinear";

var Methods: Map<String, dynamic> = new Map<String, dynamic>();
Methods.set(ColorSpaceNode.LINEAR_TO_sRGB, LinearTosRGBShader);
Methods.set(ColorSpaceNode.sRGB_TO_LINEAR, sRGBToLinearShader);

function getColorSpaceMethod(colorSpace: Dynamic): String {
  var method: String = null;

  if (colorSpace == LinearSRGBColorSpace) {
    method = "Linear";
  } else if (colorSpace == SRGBColorSpace) {
    method = "sRGB";
  }

  return method;
}

function getMethod(source: Dynamic, target: Dynamic): String {
  return getColorSpaceMethod(source) + "To" + getColorSpaceMethod(target);
}

var sRGBToLinearShader = ShaderNode.tslFn(function(inputs: {value: Node}) {
  var value = inputs.value;
  var rgb = value.rgb;

  var a = rgb.mul(0.9478672986).add(0.0521327014).pow(2.4);
  var b = rgb.mul(0.0773993808);
  var factor = rgb.lessThanEqual(0.04045);

  var rgbResult = MathNode.mix(a, b, factor);

  return ShaderNode.vec4(rgbResult, value.a);
});

var LinearTosRGBShader = ShaderNode.tslFn(function(inputs: {value: Node}) {
  var value = inputs.value;
  var rgb = value.rgb;

  var a = rgb.pow(0.41666).mul(1.055).sub(0.055);
  var b = rgb.mul(12.92);
  var factor = rgb.lessThanEqual(0.0031308);

  var rgbResult = MathNode.mix(a, b, factor);

  return ShaderNode.vec4(rgbResult, value.a);
});

function linearToColorSpace(node: Node, colorSpace: Dynamic): Node {
  return ShaderNode.nodeObject(new ColorSpaceNode(getMethod(LinearSRGBColorSpace, colorSpace), ShaderNode.nodeObject(node)));
}

function colorSpaceToLinear(node: Node, colorSpace: Dynamic): Node {
  return ShaderNode.nodeObject(new ColorSpaceNode(getMethod(colorSpace, LinearSRGBColorSpace), ShaderNode.nodeObject(node)));
}

var linearTosRGB = ShaderNode.nodeProxy(ColorSpaceNode, ColorSpaceNode.LINEAR_TO_sRGB);
var sRGBToLinear = ShaderNode.nodeProxy(ColorSpaceNode, ColorSpaceNode.sRGB_TO_LINEAR);

ShaderNode.addNodeElement("linearTosRGB", linearTosRGB);
ShaderNode.addNodeElement("sRGBToLinear", sRGBToLinear);
ShaderNode.addNodeElement("linearToColorSpace", linearToColorSpace);
ShaderNode.addNodeElement("colorSpaceToLinear", colorSpaceToLinear);

ShaderNode.addNodeClass("ColorSpaceNode", ColorSpaceNode);

export default ColorSpaceNode;