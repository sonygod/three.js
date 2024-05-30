package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.js.math.MathNode;
import three.js.math.OperatorNode;
import three.js.core.Node;

class ColorAdjustmentNode extends TempNode {
  public var method:String;
  public var colorNode:Node;
  public var adjustmentNode:Node;

  public function new(method:String, colorNode:Node, adjustmentNode:Node = Node.createFloat(1)) {
    super("vec3");
    this.method = method;
    this.colorNode = colorNode;
    this.adjustmentNode = adjustmentNode;
  }

  public function setup():Node {
    var callParams = { color: colorNode, adjustment: adjustmentNode };
    var outputNode:Node = null;
    switch (method) {
      case SATURATION:
        outputNode = saturationNode(callParams);
      case VIBRANCE:
        outputNode = vibranceNode(callParams);
      case HUE:
        outputNode = hueNode(callParams);
      default:
        trace("${this.type}: Method \"$this.method\" not supported!");
    }
    return outputNode;
  }

  static public inline var SATURATION:String = "saturation";
  static public inline var VIBRANCE:String = "vibrance";
  static public inline var HUE:String = "hue";
}

private inline function saturationNode(params:{color:Node, adjustment:Node}):Node {
  return mix(adjustment, luminance(params.color.rgb), params.color.rgb);
}

private inline function vibranceNode(params:{color:Node, adjustment:Node}):Node {
  var average = add(params.color.r, params.color.g, params.color.b).div(3.0);
  var mx = params.color.r.max(params.color.g.max(params.color.b));
  var amt = mx.sub(average).mul(adjustment).mul(-3.0);
  return mix(params.color.rgb, mx, amt);
}

private inline function hueNode(params:{color:Node, adjustment:Node}):Node {
  var k = vec3(0.57735, 0.57735, 0.57735);
  var cosAngle = adjustment.cos();
  return vec3(params.color.rgb.mul(cosAngle).add(k.cross(params.color.rgb).mul(adjustment.sin()).add(k.mul(dot(k, params.color.rgb).mul(cosAngle.sub(1))))));
}

private inline function luminance(color:Node, luma:Node = lumaCoeffs):Node {
  return dot(color, luma);
}

private inline var lumaCoeffs:Node = vec3(0.2125, 0.7154, 0.0721);

private inline function threshold(color:Node, t:Node):Node {
  return mix(vec3(0.0), color, luminance(color).sub(t).max(0));
}

private inline function addNodeElement(name:String, node:Node) {
  // todo: implement addNodeElement
}

private inline function addNodeClass(name:String, klass:Class<Dynamic>) {
  // todo: implement addNodeClass
}

private inline function nodeProxy(klass:Class<Dynamic>, method:String):Node {
  // todo: implement nodeProxy
}

// exports
var ColorAdjustmentNode:ColorAdjustmentNode;

var saturation:Node = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.SATURATION);
var vibrance:Node = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.VIBRANCE);
var hue:Node = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.HUE);

addNodeElement("saturation", saturation);
addNodeElement("vibrance", vibrance);
addNodeElement("hue", hue);
addNodeElement("threshold", threshold);

addNodeClass("ColorAdjustmentNode", ColorAdjustmentNode);