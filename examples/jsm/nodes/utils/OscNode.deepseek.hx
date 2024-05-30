import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.utils.TimerNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class OscNode extends Node {

    public var method:String;
    public var timeNode:TimerNode;

    public function new(method:String = OscNode.SINE, timeNode:TimerNode = TimerNode.timerLocal()) {
        super();
        this.method = method;
        this.timeNode = timeNode;
    }

    public function getNodeType(builder:ShaderNode.Builder):String {
        return this.timeNode.getNodeType(builder);
    }

    public function setup():ShaderNode {
        var method:String = this.method;
        var timeNode:ShaderNode = ShaderNode.nodeObject(this.timeNode);

        var outputNode:ShaderNode = null;

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

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.method = this.method;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.method = data.method;
    }

    static public var SINE:String = 'sine';
    static public var SQUARE:String = 'square';
    static public var TRIANGLE:String = 'triangle';
    static public var SAWTOOTH:String = 'sawtooth';

    static public function oscSine():ShaderNode {
        return ShaderNode.nodeProxy(OscNode, OscNode.SINE);
    }

    static public function oscSquare():ShaderNode {
        return ShaderNode.nodeProxy(OscNode, OscNode.SQUARE);
    }

    static public function oscTriangle():ShaderNode {
        return ShaderNode.nodeProxy(OscNode, OscNode.TRIANGLE);
    }

    static public function oscSawtooth():ShaderNode {
        return ShaderNode.nodeProxy(OscNode, OscNode.SAWTOOTH);
    }

    static public function addNodeClass(name:String, node:Node) {
        Node.addNodeClass(name, node);
    }
}