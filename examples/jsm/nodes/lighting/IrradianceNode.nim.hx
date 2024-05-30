import LightingNode.LightingNode;
import Node.addNodeClass;

class IrradianceNode extends LightingNode {

	var node:Node;

	public function new(node:Node) {

		super();

		this.node = node;

	}

	public function setup(builder:Builder) {

		builder.context.irradiance.addAssign( this.node );

	}

}

addNodeClass( 'IrradianceNode', IrradianceNode );