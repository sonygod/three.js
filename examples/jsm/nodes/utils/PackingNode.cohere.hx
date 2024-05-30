import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class PackingNode extends TempNode {
	public var scope:String;
	public var node;

	public function new(scope:String, node) {
		super();
		this.scope = scope;
		this.node = node;
	}

	public function getNodeType(builder) {
		return node.getNodeType(builder);
	}

	public function setup() {
		var result:Dynamic = null;

		if (scope == PackingNode.DIRECTION_TO_COLOR) {
			result = node.mul(0.5).add(0.5);
		} else if (scope == PackingNode.COLOR_TO_DIRECTION) {
			result = node.mul(2.0).sub(1);
		}

		return result;
	}
}

static var DIRECTION_TO_COLOR:String = 'directionToColor';
static var COLOR_TO_DIRECTION:String = 'colorToDirection';

static function __init__() {
	directionToColor = nodeProxy(PackingNode, DIRECTION_TO_COLOR);
	colorToDirection = nodeProxy(PackingNode, COLOR_TO_DIRECTION);

	addNodeElement('directionToColor', directionToColor);
	addNodeElement('colorToDirection', colorToDirection);

	addNodeClass('PackingNode', PackingNode);
}

static var directionToColor;
static var colorToDirection;