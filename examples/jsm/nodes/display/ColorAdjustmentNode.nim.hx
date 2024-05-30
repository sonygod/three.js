import TempNode from '../core/TempNode.js';
import { dot, mix } from '../math/MathNode.js';
import { add } from '../math/OperatorNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, tslFn, nodeProxy, float, vec3 } from '../shadernode/ShaderNode.js';

class SaturationNode {
    public static tslFn(callParams:Dynamic) {
        return callParams.adjustment.mix(luminance(callParams.color.rgb), callParams.color.rgb);
    }
}

class VibranceNode {
    public static tslFn(callParams:Dynamic) {
        const average = add(callParams.color.r, callParams.color.g, callParams.color.b).div(3.0);
        const mx = callParams.color.r.max(callParams.color.g.max(callParams.color.b));
        const amt = mx.sub(average).mul(callParams.adjustment).mul(-3.0);
        return mix(callParams.color.rgb, mx, amt);
    }
}

class HueNode {
    public static tslFn(callParams:Dynamic) {
        const k = vec3(0.57735, 0.57735, 0.57735);
        const cosAngle = callParams.adjustment.cos();
        return vec3(callParams.color.rgb.mul(cosAngle).add(k.cross(callParams.color.rgb).mul(callParams.adjustment.sin()).add(k.mul(dot(k, callParams.color.rgb).mul(cosAngle.oneMinus())))));
    }
}

class ColorAdjustmentNode extends TempNode {
    public static SATURATION = 'saturation';
    public static VIBRANCE = 'vibrance';
    public static HUE = 'hue';

    public var method:String;
    public var colorNode:Dynamic;
    public var adjustmentNode:Dynamic;

    public function new(method:String, colorNode:Dynamic, adjustmentNode:Dynamic = float(1)) {
        super('vec3');
        this.method = method;
        this.colorNode = colorNode;
        this.adjustmentNode = adjustmentNode;
    }

    public function setup():Dynamic {
        const callParams = { color: this.colorNode, adjustment: this.adjustmentNode };
        let outputNode = null;
        if (this.method == ColorAdjustmentNode.SATURATION) {
            outputNode = SaturationNode.tslFn(callParams);
        } else if (this.method == ColorAdjustmentNode.VIBRANCE) {
            outputNode = VibranceNode.tslFn(callParams);
        } else if (this.method == ColorAdjustmentNode.HUE) {
            outputNode = HueNode.tslFn(callParams);
        } else {
            console.error('${ this.type }: Method "${ this.method }" not supported!');
        }
        return outputNode;
    }
}

export default ColorAdjustmentNode;

export const saturation = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.SATURATION);
export const vibrance = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.VIBRANCE);
export const hue = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.HUE);

export const lumaCoeffs = vec3(0.2125, 0.7154, 0.0721);
export const luminance = (color:Dynamic, luma:Dynamic = lumaCoeffs) => dot(color, luma);

export const threshold = (color:Dynamic, threshold:Dynamic) => mix(vec3(0.0), color, luminance(color).sub(threshold).max(0));

addNodeElement('saturation', saturation);
addNodeElement('vibrance', vibrance);
addNodeElement('hue', hue);
addNodeElement('threshold', threshold);

addNodeClass('ColorAdjustmentNode', ColorAdjustmentNode);