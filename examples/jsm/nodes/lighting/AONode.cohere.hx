import LightingNode from LightingNode;

class AONode extends LightingNode {
	public var aoNode:Float;

	public function new(aoNode:Float) {
		super();
		this.aoNode = aoNode;
	}

	public function setup(builder:Builder) {
		var aoIntensity = 1.0;
		var aoNode = this.aoNode - 1.0 * aoIntensity + 1.0;
		builder.context.ambientOcclusion *= aoNode;
	}
}

@:export( 'default' )
class AONode {
	public static function addNodeClass() {
		Node.addNodeClass('AONode', AONode);
	}
}