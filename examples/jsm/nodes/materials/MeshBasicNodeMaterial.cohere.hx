import NodeMaterial from './NodeMaterial.hx';

class MeshBasicMaterial {
	// ... MeshBasicMaterial 类定义 ...
}

class MeshBasicNodeMaterial extends NodeMaterial {
	public var isMeshBasicNodeMaterial:Bool = true;
	public var lights:Bool;
	public var normals:Bool;

	public function new(parameters:Dynamic) {
		super();
		this.lights = false;
		this.normals = false; // @TODO: normals usage by context
		this.setDefaultValues(defaultValues);
		this.setValues(parameters);
	}

	static var defaultValues:MeshBasicMaterial;

	static function __init__() {
		defaultValues = new MeshBasicMaterial();
	}
}

@:enum(false)
class NodeMaterialTypes {
	static var MeshBasicNodeMaterial:String = 'MeshBasicNodeMaterial';
}

NodeMaterial.addNodeMaterial(NodeMaterialTypes.MeshBasicNodeMaterial, MeshBasicNodeMaterial);

class Export {
	static var default:MeshBasicNodeMaterial;
}