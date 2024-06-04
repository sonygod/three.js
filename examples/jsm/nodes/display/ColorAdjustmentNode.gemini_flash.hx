import TempNode from "../core/TempNode";
import { dot, mix } from "../math/MathNode";
import { add } from "../math/OperatorNode";
import { addNodeClass, addNodeElement, tslFn, nodeProxy, float, vec3 } from "../shadernode/ShaderNode";

var saturationNode = tslFn((color, adjustment) => {
  return adjustment.mix(luminance(color.rgb), color.rgb);
});

var vibranceNode = tslFn((color, adjustment) => {
  var average = add(color.r, color.g, color.b).div(3.0);
  var mx = color.r.max(color.g.max(color.b));
  var amt = mx.sub(average).mul(adjustment).mul(-3.0);
  return mix(color.rgb, mx, amt);
});

var hueNode = tslFn((color, adjustment) => {
  var k = vec3(0.57735, 0.57735, 0.57735);
  var cosAngle = adjustment.cos();
  return vec3(color.rgb.mul(cosAngle).add(k.cross(color.rgb).mul(adjustment.sin()).add(k.mul(dot(k, color.rgb).mul(cosAngle.oneMinus())))));
});

class ColorAdjustmentNode extends TempNode {
  public method:String;
  public colorNode:Dynamic;
  public adjustmentNode:Dynamic;

  public function new(method:String, colorNode:Dynamic, adjustmentNode:Dynamic = float(1)) {
    super('vec3');
    this.method = method;
    this.colorNode = colorNode;
    this.adjustmentNode = adjustmentNode;
  }

  override public function setup():Dynamic {
    var { method, colorNode, adjustmentNode } = this;
    var callParams = { color: colorNode, adjustment: adjustmentNode };
    var outputNode:Dynamic = null;

    if (method == ColorAdjustmentNode.SATURATION) {
      outputNode = saturationNode(callParams);
    } else if (method == ColorAdjustmentNode.VIBRANCE) {
      outputNode = vibranceNode(callParams);
    } else if (method == ColorAdjustmentNode.HUE) {
      outputNode = hueNode(callParams);
    } else {
      console.error("${this.type}: Method \"${this.method}\" not supported!");
    }

    return outputNode;
  }
}

ColorAdjustmentNode.SATURATION = 'saturation';
ColorAdjustmentNode.VIBRANCE = 'vibrance';
ColorAdjustmentNode.HUE = 'hue';

export default ColorAdjustmentNode;

export var saturation = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.SATURATION);
export var vibrance = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.VIBRANCE);
export var hue = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.HUE);

export var lumaCoeffs = vec3(0.2125, 0.7154, 0.0721);
export function luminance(color:Dynamic, luma:Dynamic = lumaCoeffs):Dynamic {
  return dot(color, luma);
}

export function threshold(color:Dynamic, threshold:Dynamic):Dynamic {
  return mix(vec3(0.0), color, luminance(color).sub(threshold).max(0));
}

addNodeElement('saturation', saturation);
addNodeElement('vibrance', vibrance);
addNodeElement('hue', hue);
addNodeElement('threshold', threshold);

addNodeClass('ColorAdjustmentNode', ColorAdjustmentNode);