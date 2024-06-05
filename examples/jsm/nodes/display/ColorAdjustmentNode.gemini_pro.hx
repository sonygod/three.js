import TempNode from "../core/TempNode";
import { dot, mix } from "../math/MathNode";
import { add } from "../math/OperatorNode";
import { addNodeClass, addNodeElement, tslFn, nodeProxy, float, vec3 } from "../shadernode/ShaderNode";

var saturationNode = tslFn((params: {color: any, adjustment: any}) => {
  return params.adjustment.mix(luminance(params.color.rgb), params.color.rgb);
});

var vibranceNode = tslFn((params: {color: any, adjustment: any}) => {
  var average = add(params.color.r, params.color.g, params.color.b).div(3.0);

  var mx = params.color.r.max(params.color.g.max(params.color.b));
  var amt = mx.sub(average).mul(params.adjustment).mul(-3.0);

  return mix(params.color.rgb, mx, amt);
});

var hueNode = tslFn((params: {color: any, adjustment: any}) => {
  var k = vec3(0.57735, 0.57735, 0.57735);

  var cosAngle = params.adjustment.cos();

  return vec3(params.color.rgb.mul(cosAngle).add(k.cross(params.color.rgb).mul(params.adjustment.sin()).add(k.mul(dot(k, params.color.rgb).mul(cosAngle.oneMinus())))));
});

class ColorAdjustmentNode extends TempNode {
  public method: string;
  public colorNode: any;
  public adjustmentNode: any;

  constructor(method: string, colorNode: any, adjustmentNode: any = float(1)) {
    super("vec3");
    this.method = method;
    this.colorNode = colorNode;
    this.adjustmentNode = adjustmentNode;
  }

  setup() {
    var { method, colorNode, adjustmentNode } = this;
    var callParams = { color: colorNode, adjustment: adjustmentNode };
    var outputNode: any = null;
    if (method == ColorAdjustmentNode.SATURATION) {
      outputNode = saturationNode(callParams);
    } else if (method == ColorAdjustmentNode.VIBRANCE) {
      outputNode = vibranceNode(callParams);
    } else if (method == ColorAdjustmentNode.HUE) {
      outputNode = hueNode(callParams);
    } else {
      console.error(`${this.type}: Method "${this.method}" not supported!`);
    }
    return outputNode;
  }
}

ColorAdjustmentNode.SATURATION = "saturation";
ColorAdjustmentNode.VIBRANCE = "vibrance";
ColorAdjustmentNode.HUE = "hue";

export default ColorAdjustmentNode;

export var saturation = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.SATURATION);
export var vibrance = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.VIBRANCE);
export var hue = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.HUE);

export var lumaCoeffs = vec3(0.2125, 0.7154, 0.0721);

export function luminance(color: any, luma: any = lumaCoeffs) {
  return dot(color, luma);
}

export function threshold(color: any, threshold: any) {
  return mix(vec3(0.0), color, luminance(color).sub(threshold).max(0));
}

addNodeElement("saturation", saturation);
addNodeElement("vibrance", vibrance);
addNodeElement("hue", hue);
addNodeElement("threshold", threshold);

addNodeClass("ColorAdjustmentNode", ColorAdjustmentNode);