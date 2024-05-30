import TempNode from '../core/TempNode.js';
import { dot, mix } from '../math/MathNode.js';
import { add } from '../math/OperatorNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, tslFn, nodeProxy, float, vec3 } from '../shadernode/ShaderNode.js';

class ColorAdjustmentNode extends TempNode {

    static var SATURATION:String = 'saturation';
    static var VIBRANCE:String = 'vibrance';
    static var HUE:String = 'hue';

    var method:String;
    var colorNode:TempNode;
    var adjustmentNode:TempNode;

    public function new(method:String, colorNode:TempNode, adjustmentNode:TempNode = float(1)) {
        super('vec3');
        this.method = method;
        this.colorNode = colorNode;
        this.adjustmentNode = adjustmentNode;
    }

    public function setup():TempNode {
        var callParams = { color: colorNode, adjustment: adjustmentNode };
        var outputNode:TempNode = null;

        if (method == SATURATION) {
            outputNode = saturationNode(callParams);
        } else if (method == VIBRANCE) {
            outputNode = vibranceNode(callParams);
        } else if (method == HUE) {
            outputNode = hueNode(callParams);
        } else {
            trace(`${this.type}: Method "${this.method}" not supported!`);
        }

        return outputNode;
    }

    static function saturationNode(params:{color:TempNode, adjustment:TempNode}):TempNode {
        return params.adjustment.mix(luminance(params.color.rgb), params.color.rgb);
    }

    static function vibranceNode(params:{color:TempNode, adjustment:TempNode}):TempNode {
        var average = add(params.color.r, params.color.g, params.color.b).div(3.0);
        var mx = params.color.r.max(params.color.g.max(params.color.b));
        var amt = mx.sub(average).mul(params.adjustment).mul(-3.0);
        return mix(params.color.rgb, mx, amt);
    }

    static function hueNode(params:{color:TempNode, adjustment:TempNode}):TempNode {
        var k = vec3(0.57735, 0.57735, 0.57735);
        var cosAngle = params.adjustment.cos();
        return vec3(params.color.rgb.mul(cosAngle).add(k.cross(params.color.rgb).mul(params.adjustment.sin()).add(k.mul(dot(k, params.color.rgb).mul(cosAngle.oneMinus())))));
    }

    static function luminance(color:TempNode, luma:TempNode = lumaCoeffs):TempNode {
        return dot(color, luma);
    }

    static function threshold(color:TempNode, threshold:TempNode):TempNode {
        return mix(vec3(0.0), color, luminance(color).sub(threshold).max(0));
    }
}

var saturation = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.SATURATION);
var vibrance = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.VIBRANCE);
var hue = nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.HUE);

var lumaCoeffs = vec3(0.2125, 0.7154, 0.0721);

addNodeElement('saturation', saturation);
addNodeElement('vibrance', vibrance);
addNodeElement('hue', hue);
addNodeElement('threshold', threshold);

addNodeClass('ColorAdjustmentNode', ColorAdjustmentNode);