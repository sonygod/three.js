import UniformNode from '../core/UniformNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { nodeObject, nodeImmutable } from '../shadernode/ShaderNode.hx';
import { addNodeClass } from '../core/Node.hx';

class TimerNode extends UniformNode {
    public var scope:String;
    public var scale:Float;

    public function new(scope:String = TimerNode.LOCAL, scale:Float = 1., value:Float = 0.) {
        super(value);
        this.scope = scope;
        this.scale = scale;
        this.updateType = NodeUpdateType.FRAME;
    }

    public function update(frame:Dynamic) {
        switch(this.scope) {
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
                // global
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

    static public var LOCAL:String = 'local';
    static public var GLOBAL:String = 'global';
    static public var DELTA:String = 'delta';
    static public var FRAME:String = 'frame';
}

static function $extend(local) {
    local.timerLocal = $bind(null, 'timerLocal');
    local.timerGlobal = $bind(null, 'timerGlobal');
    local.timerDelta = $bind(null, 'timerDelta');
    local.frameId = $bind(null, 'frameId');
    return local;
}

function timerLocal(timeScale:Float, value:Float = 0.) {
    return nodeObject(new TimerNode(TimerNode.LOCAL, timeScale, value));
}

function timerGlobal(timeScale:Float, value:Float = 0.) {
    return nodeObject(new TimerNode(TimerNode.GLOBAL, timeScale, value));
}

function timerDelta(timeScale:Float, value:Float = 0.) {
    return nodeObject(new TimerNode(TimerNode.DELTA, timeScale, value));
}

function frameId() {
    return nodeImmutable(TimerNode, TimerNode.FRAME).toUint();
}

addNodeClass('TimerNode', TimerNode);

class haxe_TimerNode {
    static public var LOCAL:String = 'local';
    static public var GLOBAL:String = 'global';
    static public var DELTA:String = 'delta';
    static public var FRAME:String = 'frame';
}

export { $extend, TimerNode, timerLocal, timerGlobal, timerDelta, frameId };