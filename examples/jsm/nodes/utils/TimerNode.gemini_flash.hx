import UniformNode from "../core/UniformNode";
import NodeUpdateType from "../core/constants";
import { nodeObject, nodeImmutable } from "../shadernode/ShaderNode";
import Node from "../core/Node";

class TimerNode extends UniformNode {
  public scope: String;
  public scale: Float;

  public function new(scope: String = TimerNode.LOCAL, scale: Float = 1, value: Float = 0) {
    super(value);
    this.scope = scope;
    this.scale = scale;
    this.updateType = NodeUpdateType.FRAME;
  }

  public function update(frame: {deltaTime: Float, frameId: Int, time: Float}): Void {
    switch (this.scope) {
      case TimerNode.LOCAL:
        this.value += frame.deltaTime * this.scale;
      case TimerNode.DELTA:
        this.value = frame.deltaTime * this.scale;
      case TimerNode.FRAME:
        this.value = frame.frameId;
      case TimerNode.GLOBAL:
        this.value = frame.time * this.scale;
    }
  }

  public function serialize(data: Dynamic): Void {
    super.serialize(data);
    data.scope = this.scope;
    data.scale = this.scale;
  }

  public function deserialize(data: Dynamic): Void {
    super.deserialize(data);
    this.scope = data.scope;
    this.scale = data.scale;
  }
}

TimerNode.LOCAL = "local";
TimerNode.GLOBAL = "global";
TimerNode.DELTA = "delta";
TimerNode.FRAME = "frame";

export default TimerNode;

export function timerLocal(timeScale: Float, value: Float = 0): Dynamic {
  return nodeObject(new TimerNode(TimerNode.LOCAL, timeScale, value));
}

export function timerGlobal(timeScale: Float, value: Float = 0): Dynamic {
  return nodeObject(new TimerNode(TimerNode.GLOBAL, timeScale, value));
}

export function timerDelta(timeScale: Float, value: Float = 0): Dynamic {
  return nodeObject(new TimerNode(TimerNode.DELTA, timeScale, value));
}

export function frameId(): Dynamic {
  return nodeImmutable(TimerNode, TimerNode.FRAME).toUint();
}

Node.addNodeClass("TimerNode", TimerNode);