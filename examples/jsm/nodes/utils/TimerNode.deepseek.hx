import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.Node;

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
		var scope:String = this.scope;
		var scale:Float = this.scale;

		if (scope == TimerNode.LOCAL) {
			this.value += frame.deltaTime * scale;
		} else if (scope == TimerNode.DELTA) {
			this.value = frame.deltaTime * scale;
		} else if (scope == TimerNode.FRAME) {
			this.value = frame.frameId;
		} else {
			// global
			this.value = frame.time * scale;
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

	public static var LOCAL:String = 'local';
	public static var GLOBAL:String = 'global';
	public static var DELTA:String = 'delta';
	public static var FRAME:String = 'frame';

	public static function timerLocal(timeScale:Float, value:Float = 0):ShaderNode {
		return ShaderNode.nodeObject(new TimerNode(TimerNode.LOCAL, timeScale, value));
	}

	public static function timerGlobal(timeScale:Float, value:Float = 0):ShaderNode {
		return ShaderNode.nodeObject(new TimerNode(TimerNode.GLOBAL, timeScale, value));
	}

	public static function timerDelta(timeScale:Float, value:Float = 0):ShaderNode {
		return ShaderNode.nodeObject(new TimerNode(TimerNode.DELTA, timeScale, value));
	}

	public static function frameId():ShaderNode {
		return ShaderNode.nodeImmutable(TimerNode, TimerNode.FRAME).toUint();
	}
}

Node.addNodeClass('TimerNode', TimerNode);