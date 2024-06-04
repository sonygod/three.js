import Node from "../core/Node";
import TimerNode from "./TimerNode";
import ShaderNode from "../shadernode/ShaderNode";

class OscNode extends Node {

    public static var SINE:String = "sine";
    public static var SQUARE:String = "square";
    public static var TRIANGLE:String = "triangle";
    public static var SAWTOOTH:String = "sawtooth";

    public var method:String;
    public var timeNode:TimerNode;

    public function new(method:String = OscNode.SINE, timeNode:TimerNode = new TimerNode()) {
        super();
        this.method = method;
        this.timeNode = timeNode;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return this.timeNode.getNodeType(builder);
    }

    public function setup():Dynamic {
        var method = this.method;
        var timeNode = ShaderNode.nodeObject(this.timeNode);

        var outputNode:Dynamic = null;

        if (method == OscNode.SINE) {
            outputNode = timeNode.add(0.75).mul(Math.PI * 2).sin().mul(0.5).add(0.5);
        } else if (method == OscNode.SQUARE) {
            outputNode = timeNode.fract().round();
        } else if (method == OscNode.TRIANGLE) {
            outputNode = timeNode.add(0.5).fract().mul(2).sub(1).abs();
        } else if (method == OscNode.SAWTOOTH) {
            outputNode = timeNode.fract();
        }

        return outputNode;
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.method = this.method;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.method = data.method;
    }

}

var oscSine = ShaderNode.nodeProxy(OscNode, OscNode.SINE);
var oscSquare = ShaderNode.nodeProxy(OscNode, OscNode.SQUARE);
var oscTriangle = ShaderNode.nodeProxy(OscNode, OscNode.TRIANGLE);
var oscSawtooth = ShaderNode.nodeProxy(OscNode, OscNode.SAWTOOTH);

Node.addNodeClass("OscNode", OscNode);

export default OscNode;
export {oscSine, oscSquare, oscTriangle, oscSawtooth};