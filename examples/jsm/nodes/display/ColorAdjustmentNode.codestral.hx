import three.nodes.core.TempNode;
import three.nodes.math.MathNode;
import three.nodes.math.OperatorNode;
import three.nodes.core.Node;
import three.shadernode.ShaderNode;

class SaturationNode extends ShaderNode {
    public function new(color:ShaderNode, adjustment:ShaderNode) {
        super();
        this.inputs = { "color": color, "adjustment": adjustment };
    }

    @:override
    public function evaluate(): ShaderNode {
        return ShaderNode.mix(luminance(this.inputs["color"]), this.inputs["color"], this.inputs["adjustment"]);
    }
}

class VibranceNode extends ShaderNode {
    public function new(color:ShaderNode, adjustment:ShaderNode) {
        super();
        this.inputs = { "color": color, "adjustment": adjustment };
    }

    @:override
    public function evaluate(): ShaderNode {
        var average = OperatorNode.add(this.inputs["color"].get("r"), this.inputs["color"].get("g"), this.inputs["color"].get("b")).div(3.0);
        var mx = this.inputs["color"].get("r").max(this.inputs["color"].get("g").max(this.inputs["color"].get("b")));
        var amt = mx.sub(average).mul(this.inputs["adjustment"]).mul(-3.0);
        return ShaderNode.mix(this.inputs["color"], mx, amt);
    }
}

class HueNode extends ShaderNode {
    public function new(color:ShaderNode, adjustment:ShaderNode) {
        super();
        this.inputs = { "color": color, "adjustment": adjustment };
    }

    @:override
    public function evaluate(): ShaderNode {
        var k = ShaderNode.vec3(0.57735, 0.57735, 0.57735);
        var cosAngle = this.inputs["adjustment"].cos();
        return ShaderNode.vec3(this.inputs["color"].get("rgb").mul(cosAngle).add(k.cross(this.inputs["color"].get("rgb")).mul(this.inputs["adjustment"].sin()).add(k.mul(MathNode.dot(k, this.inputs["color"].get("rgb")).mul(cosAngle.oneMinus())))));
    }
}

class ColorAdjustmentNode extends TempNode {
    public var method:String;
    public var colorNode:ShaderNode;
    public var adjustmentNode:ShaderNode;

    public function new(method:String, colorNode:ShaderNode, adjustmentNode:ShaderNode = ShaderNode.float(1)) {
        super("vec3");
        this.method = method;
        this.colorNode = colorNode;
        this.adjustmentNode = adjustmentNode;
    }

    public function setup(): ShaderNode {
        var outputNode:ShaderNode;
        switch (this.method) {
            case "saturation":
                outputNode = new SaturationNode(this.colorNode, this.adjustmentNode);
                break;
            case "vibrance":
                outputNode = new VibranceNode(this.colorNode, this.adjustmentNode);
                break;
            case "hue":
                outputNode = new HueNode(this.colorNode, this.adjustmentNode);
                break;
            default:
                trace("${this.type}: Method \"${this.method}\" not supported!");
                return null;
        }
        return outputNode.evaluate();
    }
}

var lumaCoeffs = ShaderNode.vec3(0.2125, 0.7154, 0.0721);
function luminance(color:ShaderNode, luma:ShaderNode = lumaCoeffs): ShaderNode {
    return MathNode.dot(color, luma);
}

function threshold(color:ShaderNode, threshold:Float): ShaderNode {
    return ShaderNode.mix(ShaderNode.vec3(0.0), color, luminance(color).sub(threshold).max(0));
}

ShaderNode.addNodeElement("saturation", (color:ShaderNode, adjustment:ShaderNode) -> new ColorAdjustmentNode("saturation", color, adjustment));
ShaderNode.addNodeElement("vibrance", (color:ShaderNode, adjustment:ShaderNode) -> new ColorAdjustmentNode("vibrance", color, adjustment));
ShaderNode.addNodeElement("hue", (color:ShaderNode, adjustment:ShaderNode) -> new ColorAdjustmentNode("hue", color, adjustment));
ShaderNode.addNodeElement("threshold", threshold);

Node.addNodeClass("ColorAdjustmentNode", ColorAdjustmentNode);