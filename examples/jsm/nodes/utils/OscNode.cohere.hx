import Node from '../core/Node.hx';
import { timerLocal } from './TimerNode.hx';
import { nodeObject, nodeProxy } from '../shadernode/ShaderNode.hx';

class OscNode extends Node {
	public var method:String = OscNode.SINE;
	public var timeNode:Node = timerLocal();

	public function new(?method:String, ?timeNode:Node) {
		super();
		this.method = method ?? OscNode.SINE;
		this.timeNode = timeNode ?? timerLocal();
	}

	public function getNodeType(builder:Dynamic) -> Node:Node {
		return this.timeNode.getNodeType(builder);
	}

	public function setup():Node {
		var method = this.method;
		var timeNode = nodeObject(this.timeNode);

		var outputNode:Node = null;

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

	public override function serialize(data:Dynamic) {
		super.serialize(data);
		data.method = this.method;
	}

	public override function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.method = data.method;
	}
}

static inline var SINE = 'sine';
static inline var SQUARE = 'square';
static inline var TRIANGLE = 'triangle';
static inline var SAWTOOTH = 'sawtooth';

static function _oscProxy(method:String) -> Node:Node {
	return nodeProxy(OscNode, method);
}

static inline var oscSine = _oscProxy(SINE);
static inline var oscSquare = _oscProxy(SQUARE);
static inline var oscTriangle = _oscProxy(TRIANGLE);
static inline var oscSawtooth = _oscProxy(SAWTOOTH);

static function __init__() {
	Node.addNodeClass('OscNode', OscNode);
}