package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.nodes.utils.TimerNode;

class OscNode extends Node {

    public static inline var SINE:String = 'sine';
    public static inline var SQUARE:String = 'square';
    public static inline var TRIANGLE:String = 'triangle';
    public static inline var SAWTOOTH:String = 'sawtooth';

    public var method:String;
    public var timeNode:TimerNode;

    public function new(?method:String = SINE, ?timeNode:TimerNode = TimerNode.localTimer) {
        super();
        this.method = method;
        this.timeNode = timeNode;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return timeNode.getNodeType(builder);
    }

    public function setup():Dynamic {
        var method = this.method;
        var timeNode = nodeObject(this.timeNode);

        var outputNode:Dynamic = null;

        if (method == SINE) {
            outputNode = timeNode.add(0.75).mul(Math.PI * 2).sin().mul(0.5).add(0.5);
        } else if (method == SQUARE) {
            outputNode = timeNode.fract().round();
        } else if (method == TRIANGLE) {
            outputNode = timeNode.add(0.5).fract().mul(2).sub(1).abs();
        } else if (method == SAWTOOTH) {
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
}

package three.js.examples.jsm.nodes.utils {

    public class OscSine extends OscNode {
        public function new(?timeNode:TimerNode = TimerNode.localTimer) {
            super(OscNode.SINE, timeNode);
        }
    }

    public class OscSquare extends OscNode {
        public function new(?timeNode:TimerNode = TimerNode.localTimer) {
            super(OscNode.SQUARE, timeNode);
        }
    }

    public class OscTriangle extends OscNode {
        public function new(?timeNode:TimerNode = TimerNode.localTimer) {
            super(OscNode.TRIANGLE, timeNode);
        }
    }

    public class OscSawtooth extends OscNode {
        public function new(?timeNode:TimerNode = TimerNode.localTimer) {
            super(OscNode.SAWTOOTH, timeNode);
        }
    }
}