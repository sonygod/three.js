import NodeMaterial from './NodeMaterial.hx';

class LineBasicMaterial {
	// ... 实现 LineBasicMaterial 类 ...
}

var defaultValues = new LineBasicMaterial();

@:build(NodeMaterial)
class LineBasicNodeMaterial extends NodeMaterial {
	public function new(parameters:Dynamic) {
		super();

		this.isLineBasicNodeMaterial = true;
		this.lights = false;
		this.normals = false;

		this.setDefaultValues(defaultValues);
		this.setValues(parameters);
	}
}

@:export(default)
class ExportClass {
	public static function get_LineBasicNodeMaterial() {
		return LineBasicNodeMaterial;
	}
}

@:using(NodeMaterial.registerNodeMaterial)
class Register {
	public static function main() {
		NodeMaterial.registerNodeMaterial('LineBasicNodeMaterial', LineBasicNodeMaterial);
	}
}