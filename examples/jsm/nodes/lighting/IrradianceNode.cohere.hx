import LightingNode from './LightingNode.hx';

class IrradianceNode extends LightingNode {
	public function new(node:Dynamic) {
		super();
		this.node = node;
	}

	public function setup(builder:Dynamic) {
		builder.context.irradiance.addAssign(this.node);
	}
}

@:expose("IrradianceNode")
class ExposedIrradianceNode {
	public static var __assignable__:Array<String> = ['new'];
}

class IrradianceNodeExports {
	public static function addNodeClass(name:String, node:Dynamic) {
		// Add your custom logic here for adding node class
	}
}

IrradianceNodeExports.addNodeClass('IrradianceNode', ExposedIrradianceNode);