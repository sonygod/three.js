package three.js.examples.jsw.nodes.utils;

import three.js.core.Node;
import three.js.nodes.utils.TimerNode;

class OscNode extends Node {

    public static inline var SINE:String = 'sine';
    public static inline var SQUARE:String = 'square';
    public static inline var TRIANGLE:String = 'triangle';
    public static inline var SAWTOOTH:String = 'sawtooth';

    private var method:String;
    private var timeNode:TimerNode;

    public function new(?method:String = SINE, ?timeNode:TimerNode = TimerNode.timerLocal()) {
        super();
        this.method = method;
        this.timeNode = timeNode;
    }

    override public function getNodeType(builder:Dynamic):Dynamic {
        return timeNode.getNodeType(builder);
    }

    public function setup():Dynamic {
        var timeNode:Dynamic = nodeObject(this.timeNode);
        var outputNode:Dynamic = null;

        switch (method) {
            case SINE:
                outputNode = timeNode.add(0.75).mul(Math.PI * 2).sin().mul(0.5).add(0.5);
            case SQUARE:
                outputNode = timeNode.fract().round();
            case TRIANGLE:
                outputNode = timeNode.add(0.5).fract().mul(2).sub(1).abs();
            case SAWTOOTH:
                outputNode = timeNode.fract();
        }

        return outputNode;
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.method = method;
    }

    override public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        method = data.method;
    }
}

extern class nodeProxy {
    public static function proxy(nodeClass:Class<OscNode>, method:String):OscNode {
        return Type.createInstance(nodeClass, [method]);
    }
}

var oscSine:OscNode = nodeProxy.proxy(OscNode, OscNode.SINE);
var oscSquare:OscNode = nodeProxy.proxy(OscNode, OscNode.SQUARE);
var oscTriangle:OscNode = nodeProxy.proxy(OscNode, OscNode.TRIANGLE);
var oscSawtooth:OscNode = nodeProxy.proxy(OscNode, OscNode.SAWTOOTH);

Node.addNodeClass('OscNode', OscNode);