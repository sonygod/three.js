import NodeMaterial from './NodeMaterial.hx';

class PointsMaterial {
	public var defaultValues:Dynamic;
	public function new() {
		this.defaultValues = { };
	}
}

class PointsNodeMaterial extends NodeMaterial {
	public var isPointsNodeMaterial:Bool;
	public var lights:Bool;
	public var normals:Bool;
	public var transparent:Bool;
	public var sizeNode:Node;

	public function new(parameters:Map<String, Dynamic> = null) {
		super();
		this.isPointsNodeMaterial = true;
		this.lights = false;
		this.normals = false;
		this.transparent = true;
		this.setDefaultValues(new PointsMaterial().defaultValues);
		this.setValues(parameters);
	}

	public function copy(source:PointsNodeMaterial):Void {
		this.sizeNode = source.sizeNode;
		super.copy(source);
	}
}

@:jsRequire("addNodeMaterial('PointsNodeMaterial', PointsNodeMaterial)")
class Export {
}

class Main {
	static public function main() {
		#if js
			js.Browser.window.PointsNodeMaterial = PointsNodeMaterial;
		#end
	}
}