import TempNode from '../core/TempNode.hx';
import { MathNode, dot, mix } from '../math/MathNode.hx';
import { OperatorNode, add } from '../math/OperatorNode.hx';
import { ShaderNode, addNodeClass, addNodeElement, nodeProxy, float, vec3, tslFn } from '../shadernode/ShaderNode.hx';

const saturationNode = tslFn( ({ color, adjustment }) => {
  return adjustment.mix(luminance(color.rgb), color.rgb);
});

const vibranceNode = tslFn( ({ color, adjustment }) => {
  const average = add(color.r, color.g, color.b).div(3.0);
  const mx = color.r.max(color.g.max(color.b));
  const amt = mx.sub(average).mul(adjustment).mul(-3.0);
  return mix(color.rgb, mx, amt);
});

const hueNode = tslFn( ({ color, adjustment }) => {
  const k = vec3(0.57735, 0.57735, 0.57735);
  const cosAngle = adjustment.cos();
  return vec3(color.rgb.mul(cosAngle).add(k.cross(color.rgb).mul(adjustment.sin()).add(k.mul(dot(k, color.rgb).mul(cosAngle.oneMinus())))));
});

class ColorAdjustmentNode extends TempNode {
  public method: String;
  public colorNode: any;
  public adjustmentNode: any;
  public function new(method: String, colorNode: any, adjustmentNode: Float = 1.0) {
    super('vec3');
    this.method = method;
    this.colorNode = colorNode;
    this.adjustmentNode = adjustmentNode;
  }
  public function setup(): any {
    const { method, colorNode, adjustmentNode } = this;
    const callParams = { color: colorNode, adjustment: adjustmentNode };
    var outputNode: any = null;
    switch (method) {
      case ColorAdjustmentNode.SATURATION:
        outputNode = saturationNode(callParams);
        break;
      case ColorAdjustmentNode.VIBRANCE:
        outputNode = vibranceNode(callParams);
        break;
      case ColorAdjustmentNode.HUE:
        outputNode = hueNode(callParams);
        break;
      default:
        trace(`${this.getClassName()}: Method "${method}" not supported!`);
    }
    return outputNode;
  }
}

class _ColorAdjustmentNodeStatics {
  static public SATURATION: String = 'saturation';
  static public VIBRANCE: String = 'vibrance';
  static public HUE: String = 'hue';
}

var ColorAdjustmentNode_static = _ColorAdjustmentNodeStatics;
ColorAdjustmentNode.SATURATION = ColorAdjustmentNode_static.SATURATION;
ColorAdjustmentNode.VIBRANCE = ColorAdjustmentNode_static.VIBRANCE;
ColorAdjustmentNode.HUE = ColorAdjustmentNode_static.HUE;

static function $concat<T> (a: Array<T>, b: Array<T>) : Array<T> {
  if (a == null) return b;
  if (b == null) return a;
  return a.concat(b);
}

export default ColorAdjustmentNode;

export var saturation = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.SATURATION);
export var vibrance = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.VIBRANCE);
export var hue = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.HUE);

export var lumaCoeffs = vec3(0.2125, 0.7154, 0.0721);
export function luminance(color: any, luma: any = lumaCoeffs) {
  return dot(color, luma);
}

export function threshold(color: any, threshold: Float) {
  return mix(vec3(0.0), color, luminance(color).sub(threshold).max(0));
}

addNodeElement('saturation', saturation);
addNodeElement('vibrance', vibrance);
addNodeElement('hue', hue);
addNodeElement('threshold', threshold);

addNodeClass('ColorAdjustmentNode', ColorAdjustmentNode);