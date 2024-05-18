package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.math.MathNode;
import three.math.OperatorNode;
import three.core.Node;

using three.shadernode.ShaderNode;

class ColorAdjustmentNode extends TempNode {
    public static inline var SATURATION:String = 'saturation';
    public static inline var VIBRANCE:String = 'vibrance';
    public static inline var HUE:String = 'hue';

    public var method:String;
    public var colorNode:ShaderNode;
    public var adjustmentNode:ShaderNode;

    public function new(method:String, colorNode:ShaderNode, ?adjustmentNode:ShaderNode) {
        super('vec3');
        this.method = method;
        this.colorNode = colorNode;
        this.adjustmentNode = adjustmentNode != null ? adjustmentNode : float(1);
    }

    override public function setup():ShaderNode {
        var callParams = { color: colorNode, adjustment: adjustmentNode };
        var outputNode:ShaderNode = null;

        switch (method) {
            case SATURATION:
                outputNode = saturationNode(callParams);
            case VIBRANCE:
                outputNode = vibranceNode(callParams);
            case HUE:
                outputNode = hueNode(callParams);
            default:
                trace('${this.type}: Method "${this.method}" not supported!');
        }

        return outputNode;
    }
}

class MathNode {
    public static inline function dot(a:ShaderNode, b:ShaderNode):ShaderNode {
        return new OperatorNode('dot', [a, b]);
    }

    public static inline function mix(a:ShaderNode, b:ShaderNode, c:ShaderNode):ShaderNode {
        return new OperatorNode('mix', [a, b, c]);
    }

    public static inline function add(a:ShaderNode, b:ShaderNode, ?c:ShaderNode):ShaderNode {
        return new OperatorNode('add', [a, b, c]);
    }
}

class ShaderNode {
    public static inline function tslFn(f:Dynamic):ShaderNode {
        return new ShaderNode(f);
    }

    public static inline function nodeProxy(cls:Class<ColorAdjustmentNode>, method:String):ColorAdjustmentNode {
        return new cls(method, null, null);
    }

    public static inline function addNodeElement(name:String, node:ColorAdjustmentNode):Void {
        // implementation depends on the Haxe target
    }

    public static inline function addNodeClass(name:String, nodeClass:Class<ColorAdjustmentNode>):Void {
        // implementation depends on the Haxe target
    }
}

class ColorAdjustmentNodeMacro {
    public static function build():Void {
        var saturationNode:ShaderNode = tslFn(function(params:{ color:ShaderNode, adjustment:ShaderNode }):ShaderNode {
            return mix(luminance(params.color.rgb), params.color.rgb, params.adjustment);
        });

        var vibranceNode:ShaderNode = tslFn(function(params:{ color:ShaderNode, adjustment:ShaderNode }):ShaderNode {
            var average:ShaderNode = add(params.color.r, params.color.g, params.color.b).div(3.0);
            var mx:ShaderNode = max(params.color.r, max(params.color.g, params.color.b));
            var amt:ShaderNode = mx.sub(average).mul(params.adjustment).mul(-3.0);
            return mix(params.color.rgb, mx, amt);
        });

        var hueNode:ShaderNode = tslFn(function(params:{ color:ShaderNode, adjustment:ShaderNode }):ShaderNode {
            var k:ShaderNode = vec3(0.57735, 0.57735, 0.57735);
            var cosAngle:ShaderNode = cos(params.adjustment);
            return vec3(params.color.rgb.mul(cosAngle).add(k.cross(params.color.rgb).mul(sin(params.adjustment)).add(k.mul(dot(k, params.color.rgb).mul(cosAngle.oneMinus())))));
        });

        addNodeElement('saturation', nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.SATURATION));
        addNodeElement('vibrance', nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.VIBRANCE));
        addNodeElement('hue', nodeProxy(ColorAdjustmentNode, ColorAdjustmentNode.HUE));

        addNodeClass('ColorAdjustmentNode', ColorAdjustmentNode);
    }
}

// exported constants
var lumaCoeffs:ShaderNode = vec3(0.2125, 0.7154, 0.0721);
var luminance:ShaderNode->ShaderNode = function(color:ShaderNode, ?luma:ShaderNode):ShaderNode {
    return dot(color, luma != null ? luma : lumaCoeffs);
}

var threshold:ShaderNode->ShaderNode->ShaderNode = function(color:ShaderNode, threshold:ShaderNode):ShaderNode {
    return mix(vec3(0.0), color, luminance(color).sub(threshold).max(0));
}

addNodeElement('threshold', threshold);