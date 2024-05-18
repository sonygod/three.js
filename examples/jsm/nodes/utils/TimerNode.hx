package three.js.examples.jsm.nodes.utils;

import three.js.core.UniformNode;
import three.js.core.NodeUpdateType;
import three.js.shadernode.ShaderNode;

class TimerNode extends UniformNode {

    public static inline var LOCAL:String = 'local';
    public static inline var GLOBAL:String = 'global';
    public static inline var DELTA:String = 'delta';
    public static inline var FRAME:String = 'frame';

    public var scope:String;
    public var scale:Float;

    public function new(scope:String = LOCAL, scale:Float = 1, value:Float = 0) {
        super(value);
        this.scope = scope;
        this.scale = scale;
        this.updateType = NodeUpdateType.FRAME;
    }

    override public function update(frame:Dynamic) {
        switch (scope) {
            case LOCAL:
                value += frame.deltaTime * scale;
            case DELTA:
                value = frame.deltaTime * scale;
            case FRAME:
                value = frame.frameId;
            default:
                // global
                value = frame.time * scale;
        }
    }

    override public function serialize(data:Dynamic) {
        super.serialize(data);
        data.scope = scope;
        data.scale = scale;
    }

    override public function deserialize(data:Dynamic) {
        super.deserialize(data);
        scope = data.scope;
        scale = data.scale;
    }
}

// @TODO: add support to use node in timeScale
class TimerNodeUtils {
    public static function timerLocal(timeScale:Float, value:Float = 0):ShaderNode {
        return nodeObject(new TimerNode(TimerNode.LOCAL, timeScale, value));
    }

    public static function timerGlobal(timeScale:Float, value:Float = 0):ShaderNode {
        return nodeObject(new TimerNode(TimerNode.GLOBAL, timeScale, value));
    }

    public static function timerDelta(timeScale:Float, value:Float = 0):ShaderNode {
        return nodeObject(new TimerNode(TimerNode.DELTA, timeScale, value));
    }

    public static var frameId(get, never):ShaderNode;
    private static function get_frameId():ShaderNode {
        return nodeImmutable(TimerNode, TimerNode.FRAME).toUint();
    }
}

 Node.addNodeType("TimerNode", TimerNode);