import TempNode from '../core/TempNode.hx';
import { mix } from '../math/MathNode.hx';
import { addNodeClass, nodeObject, nodeProxy, vec4 } from '../shadernode/ShaderNode.hx';

class ColorSpaceNode extends TempNode {
    public method: String;
    public node: TempNode;

    public function new(method: String, node: TempNode) {
        super('vec4');
        this.method = method;
        this.node = node;
    }

    public function setup(): TempNode {
        if (this.method == ColorSpaceNode.LINEAR_TO_LINEAR)
            return this.node;

        return Methods[this.method]({ value: this.node });
    }
}

class ColorSpaceNodeClass {
    public static get LINEAR_TO_LINEAR(): String {
        return 'LinearToLinear';
    }

    public static get LINEAR_TO_sRGB(): String {
        return 'LinearTosRGB';
    }

    public static get sRGB_TO_LINEAR(): String {
        return 'sRGBToLinear';
    }
}

var Methods = {
    $get(key: String): Dynamic {
        switch(key) {
            case ColorSpaceNode.LINEAR_TO_sRGB:
                return LinearTosRGBShader;
            case ColorSpaceNode.sRGB_TO_LINEAR:
                return sRGBToLinearShader;
        }
    }
};

function sRGBToLinearShader(inputs: {value: TempNode}): TempNode {
    var value = inputs.value;
    var rgb = value.rgb;

    var a = rgb.mul(0.9478672986).add(0.0521327014).pow(2.4);
    var b = rgb.mul(0.0773993808);
    var factor = rgb.lessThanEqual(0.04045);

    var rgbResult = mix(a, b, factor);

    return vec4(rgbResult, value.a);
}

function LinearTosRGBShader(inputs: {value: TempNode}): TempNode {
    var value = inputs.value;
    var rgb = value.rgb;

    var a = rgb.pow(0.41666).mul(1.055).sub(0.055);
    var b = rgb.mul(12.92);
    var factor = rgb.lessThanEqual(0.0031308);

    var rgbResult = mix(a, b, factor);

    return vec4(rgbResult, value.a);
}

function getColorSpaceMethod(colorSpace: Dynamic): String {
    var method: String = null;

    switch(colorSpace) {
        case LinearSRGBColorSpace:
            method = 'Linear';
            break;
        case SRGBColorSpace:
            method = 'sRGB';
            break;
    }

    return method;
}

function getMethod(source: Dynamic, target: Dynamic): String {
    return getColorSpaceMethod(source) + 'To' + getColorSpaceMethod(target);
}

function linearToColorSpace(node: TempNode, colorSpace: Dynamic): TempNode {
    return nodeObject(new ColorSpaceNode(getMethod(LinearSRGBColorSpace, colorSpace), nodeObject(node)));
}

function colorSpaceToLinear(node: TempNode, colorSpace: Dynamic): TempNode {
    return nodeObject(new ColorSpaceNode(getMethod(colorSpace, LinearSRGBColorSpace), nodeObject(node)));
}

addNodeClass('ColorSpaceNode', ColorSpaceNode);
addNodeElement('linearTosRGB', nodeProxy(ColorSpaceNode, ColorSpaceNode.LINEAR_TO_sRGB));
addNodeElement('sRGBToLinear', nodeProxy(ColorSpaceNode, ColorSpaceNode.sRGB_TO_LINEAR));
addNodeElement('linearToColorSpace', linearToColorSpace);
addNodeElement('colorSpaceToLinear', colorSpaceToLinear);

export { ColorSpaceNode, linearToColorSpace, colorSpaceToLinear };