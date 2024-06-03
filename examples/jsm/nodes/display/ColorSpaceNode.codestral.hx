import js.Browser.document;
import js.html.Element;

import three.js.nodes.core.TempNode;
import three.js.nodes.math.MathNode;
import three.js.nodes.core.Node;
import three.js.nodes.shadernode.ShaderNode;
import three.js.LinearSRGBColorSpace;
import three.js.SRGBColorSpace;

class ColorSpaceNode extends TempNode {
    public var method:String;
    public var node:ShaderNode;

    public function new(method:String, node:ShaderNode) {
        super('vec4');
        this.method = method;
        this.node = node;
    }

    public function setup():ShaderNode {
        if (this.method == ColorSpaceNode.LINEAR_TO_LINEAR)
            return this.node;

        return Methods.get(this.method).call({value: this.node});
    }

    public static var LINEAR_TO_LINEAR:String = 'LinearToLinear';
    public static var LINEAR_TO_sRGB:String = 'LinearTosRGB';
    public static var sRGB_TO_LINEAR:String = 'sRGBToLinear';
}

var LinearTosRGBShader = ShaderNode.tslFn((inputs:Dynamic) => {
    var value = inputs.value;
    var rgb = value.rgb;

    var a = rgb.mul(0.9478672986).add(0.0521327014).pow(2.4);
    var b = rgb.mul(0.0773993808);
    var factor = rgb.lessThanEqual(0.04045);

    var rgbResult = MathNode.mix(a, b, factor);

    return ShaderNode.vec4(rgbResult, value.a);
});

var sRGBToLinearShader = ShaderNode.tslFn((inputs:Dynamic) => {
    var value = inputs.value;
    var rgb = value.rgb;

    var a = rgb.pow(0.41666).mul(1.055).sub(0.055);
    var b = rgb.mul(12.92);
    var factor = rgb.lessThanEqual(0.0031308);

    var rgbResult = MathNode.mix(a, b, factor);

    return ShaderNode.vec4(rgbResult, value.a);
});

static function getColorSpaceMethod(colorSpace:Dynamic):String {
    if (colorSpace == LinearSRGBColorSpace) {
        return 'Linear';
    } else if (colorSpace == SRGBColorSpace) {
        return 'sRGB';
    }

    return null;
}

static function getMethod(source:Dynamic, target:Dynamic):String {
    return getColorSpaceMethod(source) + 'To' + getColorSpaceMethod(target);
}

var Methods = new haxe.ds.StringMap<Dynamic>();
Methods.set(ColorSpaceNode.LINEAR_TO_sRGB, LinearTosRGBShader);
Methods.set(ColorSpaceNode.sRGB_TO_LINEAR, sRGBToLinearShader);

function linearToColorSpace(node:Dynamic, colorSpace:Dynamic):ShaderNode {
    return ShaderNode.nodeObject(new ColorSpaceNode(getMethod(LinearSRGBColorSpace, colorSpace), ShaderNode.nodeObject(node)));
}

function colorSpaceToLinear(node:Dynamic, colorSpace:Dynamic):ShaderNode {
    return ShaderNode.nodeObject(new ColorSpaceNode(getMethod(colorSpace, LinearSRGBColorSpace), ShaderNode.nodeObject(node)));
}

function linearTosRGB(node:Dynamic):ShaderNode {
    return ShaderNode.nodeProxy(ColorSpaceNode, ColorSpaceNode.LINEAR_TO_sRGB);
}

function sRGBToLinear(node:Dynamic):ShaderNode {
    return ShaderNode.nodeProxy(ColorSpaceNode, ColorSpaceNode.sRGB_TO_LINEAR);
}

ShaderNode.addNodeElement('linearTosRGB', linearTosRGB);
ShaderNode.addNodeElement('sRGBToLinear', sRGBToLinear);
ShaderNode.addNodeElement('linearToColorSpace', linearToColorSpace);
ShaderNode.addNodeElement('colorSpaceToLinear', colorSpaceToLinear);

Node.addNodeClass('ColorSpaceNode', ColorSpaceNode);