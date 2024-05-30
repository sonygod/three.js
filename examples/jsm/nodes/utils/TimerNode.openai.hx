package three.js.examples.jsm.nodes.utils;

import three.js.core.UniformNode;
import three.js.core.NodeUpdateType;
import three.js.shadernode.ShaderNode;

class TimerNode extends UniformNode {

    public static inline var LOCAL = 'local';
    public static inline var GLOBAL = 'global';
    public static inline var DELTA = 'delta';
    public static inline var FRAME = 'frame';

    public var scope:String;
    public var scale:Float;

    public function new(?scope:String = LOCAL, ?scale:Float = 1, ?value:Float = 0) {
        super(value);
        this.scope = scope;
        this.scale = scale;
        updateType = NodeUpdateType.FRAME;
    }

    /*
    TODO:
    public function getNodeType(builder:Dynamic) {
        if (scope == FRAME) {
            return 'uint';
        }
        return 'float';
    }
    */

    public function update(frame:Dynamic) {
        if (scope == LOCAL) {
            value += frame.deltaTime * scale;
        } else if (scope == DELTA) {
            value = frame.deltaTime * scale;
        } else if (scope == FRAME) {
            value = frame.frameId;
        } else {
            value = frame.time * scale;
        }
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.scope = scope;
        data.scale = scale;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        scope = data.scope;
        scale = data.scale;
    }
}

// Factory functions
public function timerLocal(timeScale:Float, value:Float = 0) return nodeObject(new TimerNode(TimerNode.LOCAL, timeScale, value));
public function timerGlobal(timeScale:Float, value:Float = 0) return nodeObject(new TimerNode(TimerNode.GLOBAL, timeScale, value));
public function timerDelta(timeScale:Float, value:Float = 0) return nodeObject(new TimerNode(TimerNode.DELTA, timeScale, value));
public function frameId() return nodeImmutable(TimerNode, TimerNode.FRAME).toUint();

// Register the node class
addNodeClass('TimerNode', TimerNode);