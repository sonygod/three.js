import NodeVar from "./NodeVar";

class NodeVarying extends NodeVar {
	public var needsInterpolation:Bool = false;
	public var isNodeVarying:Bool = true;

	public function new(name:String, type:String) {
		super(name, type);
	}
}

class NodeVarying {
	public static var default:NodeVarying;

	static function init() {
		default = new NodeVarying("", "");
	}
}

NodeVarying.init();