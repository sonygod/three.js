package three.js.examples.jvm.nodes.display;

import three.js.core.TempNode;
import three.js.math.MathNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;

class ColorSpaceNode extends TempNode {
    public var method:String;
    public var node:TempNode;

    public function new(method:String, node:TempNode) {
        super('vec4');
        this.method = method;
        this.node = node;
    }

    override public function setup():TempNode {
        if (method == 'LinearToLinear') return node;
        return Methods.get(method)({ value: node });
    }
}

class ColorSpaceNodeMethods {
    public static var LINEAR_TO_LINEAR:String = 'LinearToLinear';
    public static var LINEAR_TO_sRGB:String = 'LinearTosRGB';
    public static var sRGB_TO_LINEAR:String = 'sRGBToLinear';

    public static var Methods:Map<String, ShaderNode> = [
        LINEAR_TO_sRGB => new ShaderNode(tslFn(function(inputs) {
            var value = inputs.value;
            var rgb = value.rgb;
            var a = rgb.mul(0.9478672986).add(0.0521327014).pow(2.4);
            var b = rgb.mul(0.0773993808);
            var factor = rgb.lessThanEqual(0.04045);
            var rgbResult = mix(a, b, factor);
            return vec4(rgbResult, value.a);
        })),
        sRGB_TO_LINEAR => new ShaderNode(tslFn(function(inputs) {
            var value = inputs.value;
            var rgb = value.rgb;
            var a = rgb.pow(0.41666).mul(1.055).sub(0.055);
            var b = rgb.mul(12.92);
            var factor = rgb.lessThanEqual(0.0031308);
            var rgbResult = mix(a, b, factor);
            return vec4(rgbResult, value.a);
        })),
    ];
}

class ColorSpace {
    public static function getColorSpaceMethod(colorSpace:Enum<LinearSRGBColorSpace, SRGBColorSpace>):String {
        return switch (colorSpace) {
            case LinearSRGBColorSpace: 'Linear';
            case SRGBColorSpace: 'sRGB';
        }
    }

    public static function getMethod(source:Enum<LinearSRGBColorSpace, SRGBColorSpace>, target:Enum<LinearSRGBColorSpace, SRGBColorSpace>):String {
        return getColorSpaceMethod(source) + 'To' + getColorSpaceMethod(target);
    }
}

// Exported functions
public function linearToColorSpace(node:TempNode, colorSpace:Enum<LinearSRGBColorSpace, SRGBColorSpace>):TempNode {
    return new ColorSpaceNode(getMethod(LinearSRGBColorSpace, colorSpace), node);
}

public function colorSpaceToLinear(node:TempNode, colorSpace:Enum<LinearSRGBColorSpace, SRGBColorSpace>):TempNode {
    return new ColorSpaceNode(getMethod(colorSpace, LinearSRGBColorSpace), node);
}

// Node elements
public function linearTosRGB(node:TempNode):TempNode {
    return new ColorSpaceNode(ColorSpaceNodeMethods.LINEAR_TO_sRGB, node);
}

public function sRGBToLinear(node:TempNode):TempNode {
    return new ColorSpaceNode(ColorSpaceNodeMethods.sRGB_TO_LINEAR, node);
}

// Add node elements
ShaderNode.addNodeElement('linearTosRGB', linearTosRGB);
ShaderNode.addNodeElement('sRGBToLinear', sRGBToLinear);
ShaderNode.addNodeElement('linearToColorSpace', linearToColorSpace);
ShaderNode.addNodeElement('colorSpaceToLinear', colorSpaceToLinear);

Node.addNodeClass('ColorSpaceNode', ColorSpaceNode);