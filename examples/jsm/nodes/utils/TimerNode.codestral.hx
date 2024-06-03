import UniformNode from '../core/UniformNode';
import NodeUpdateType from '../core/constants.NodeUpdateType';
import NodeClass from '../core/Node.NodeClass';
import ShaderNode from '../shadernode/ShaderNode';

class TimerNode extends UniformNode {
    public var scope:String;
    public var scale:Float;

    public function new(scope:String = TimerNode.LOCAL, scale:Float = 1, value:Float = 0) {
        super(value);
        this.scope = scope;
        this.scale = scale;
        this.updateType = NodeUpdateType.FRAME;
    }

    public function update(frame:Dynamic) {
        switch (this.scope) {
            case TimerNode.LOCAL:
                this.value += frame.deltaTime * this.scale;
                break;
            case TimerNode.DELTA:
                this.value = frame.deltaTime * this.scale;
                break;
            case TimerNode.FRAME:
                this.value = frame.frameId;
                break;
            default:
                this.value = frame.time * this.scale;
        }
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.scope = this.scope;
        data.scale = this.scale;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.scope = data.scope;
        this.scale = data.scale;
    }
}

TimerNode.LOCAL = 'local';
TimerNode.GLOBAL = 'global';
TimerNode.DELTA = 'delta';
TimerNode.FRAME = 'frame';

function timerLocal(timeScale:Float, value:Float = 0):ShaderNode {
    return ShaderNode.nodeObject(new TimerNode(TimerNode.LOCAL, timeScale, value));
}

function timerGlobal(timeScale:Float, value:Float = 0):ShaderNode {
    return ShaderNode.nodeObject(new TimerNode(TimerNode.GLOBAL, timeScale, value));
}

function timerDelta(timeScale:Float, value:Float = 0):ShaderNode {
    return ShaderNode.nodeObject(new TimerNode(TimerNode.DELTA, timeScale, value));
}

var frameId = ShaderNode.nodeImmutable(NodeClass.getByName("TimerNode"), TimerNode.FRAME).toUint();

NodeClass.add("TimerNode", TimerNode);