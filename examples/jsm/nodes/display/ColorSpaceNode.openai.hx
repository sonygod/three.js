package three.js.examples.jsm.nodes.display;

import nodes.core.TempNode;
import math.MathNode;
import nodes.core.Node;
import shadernode.ShaderNode;

import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;

class ColorSpaceNode extends TempNode<TVec4> {
    
    public var method:String;
    public var node:Node;

    public function new(method:String, node:Node) {
        super(TVec4);
        this.method = method;
        this.node = node;
    }

    override public function setup():Node {
        if (method == LINEAR_TO_LINEAR) {
            return node;
        }
        return METHODS[method]({ value: node });
    }

    public static inline var LINEAR_TO_LINEAR = 'LinearToLinear';
    public static inline var LINEAR_TO_sRGB = 'LinearTosRGB';
    public static inline var sRGB_TO_LINEAR = 'sRGBToLinear';
}

class ColorSpaceMethods {
    public static var METHODS:Map<String, TShaderFunction> = [
        ColorSpaceNode.LINEAR_TO_sRGB => LinearTosRGBShader,
        ColorSpaceNode.sRGB_TO_LINEAR => sRGBToLinearShader
    ];
}

function sRGBToLinearShader(inputs:TShaderInputs):TVec4 {
    var value:TV4 = inputs.value;
    var rgb:TV3 = value.rgb;
    var a:TV1 = rgb.mul(0.9478672986).add(0.0521327014).pow(2.4);
    var b:TV1 = rgb.mul(0.0773993808);
    var factor:TV1 = rgb.lessThanEqual(0.04045);
    var rgbResult:TV3 = mix(a, b, factor);
    return new TV4(rgbResult, value.a);
}

function LinearTosRGBShader(inputs:TShaderInputs):TVec4 {
    var value:TV4 = inputs.value;
    var rgb:TV3 = value.rgb;
    var a:TV1 = rgb.pow(0.41666).mul(1.055).sub(0.055);
    var b:TV1 = rgb.mul(12.92);
    var factor:TV1 = rgb.lessThanEqual(0.0031308);
    var rgbResult:TV3 = mix(a, b, factor);
    return new TV4(rgbResult, value.a);
}

function getColorSpaceMethod(colorSpace:ThreeColorSpace):String {
    return switch (colorSpace) {
        case LinearSRGBColorSpace:
            'Linear';
        case SRGBColorSpace:
            'sRGB';
    }
}

function getMethod(source:ThreeColorSpace, target:ThreeColorSpace):String {
    return getColorSpaceMethod(source) + 'To' + getColorSpaceMethod(target);
}

function linearToColorSpace(node:Node, colorSpace:ThreeColorSpace):Node {
    return new NodeObject(new ColorSpaceNode(getMethod(LinearSRGBColorSpace, colorSpace), nodeObject(node)));
}

function colorSpaceToLinear(node:Node, colorSpace:ThreeColorSpace):Node {
    return new NodeObject(new ColorSpaceNode(getMethod(colorSpace, LinearSRGBColorSpace), nodeObject(node)));
}

var linearTosRGB:Node = nodeProxy(ColorSpaceNode, ColorSpaceNode.LINEAR_TO_sRGB);
var sRGBToLinear:Node = nodeProxy(ColorSpaceNode, ColorSpaceNode.sRGB_TO_LINEAR);

addNodeElement('linearTosRGB', linearTosRGB);
addNodeElement('sRGBToLinear', sRGBToLinear);
addNodeElement('linearToColorSpace', linearToColorSpace);
addNodeElement('colorSpaceToLinear', colorSpaceToLinear);

addNodeClass('ColorSpaceNode', ColorSpaceNode);