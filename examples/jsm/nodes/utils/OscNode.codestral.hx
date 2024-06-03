import Node from '../core/Node';
import addNodeClass from '../core/Node';
import timerLocal from './TimerNode';
import nodeObject from '../shadernode/ShaderNode';
import nodeProxy from '../shadernode/ShaderNode';

class OscNode extends Node {

    public var method:String;
    public var timeNode:Dynamic;

    public function new(method:String = OscNode.SINE, timeNode:Dynamic = timerLocal()) {
        super();
        this.method = method;
        this.timeNode = timeNode;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return this.timeNode.getNodeType(builder);
    }

    public function setup():Dynamic {
        var method = this.method;
        var timeNode = nodeObject(this.timeNode);

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

OscNode.SINE = 'sine';
OscNode.SQUARE = 'square';
OscNode.TRIANGLE = 'triangle';
OscNode.SAWTOOTH = 'sawtooth';

var oscSine = nodeProxy(OscNode, OscNode.SINE);
var oscSquare = nodeProxy(OscNode, OscNode.SQUARE);
var oscTriangle = nodeProxy(OscNode, OscNode.TRIANGLE);
var oscSawtooth = nodeProxy(OscNode, OscNode.SAWTOOTH);

addNodeClass('OscNode', OscNode);