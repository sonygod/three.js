import three.materials.MeshBasicMaterial;
import three.materials.NodeMaterial;

class MeshBasicNodeMaterial extends NodeMaterial {

	public var isMeshBasicNodeMaterial:Bool = true;

	public var lights:Bool = false;
	//public var normals:Bool = false; @TODO: normals usage by context

	public function new(parameters:Dynamic = null) {
		super();

		this.setDefaultValues(new MeshBasicMaterial());
		this.setValues(parameters);
	}

}

class NodeMaterial {
	public static function addNodeMaterial(name:String, materialClass:Class<NodeMaterial>) {
		// TODO: Implement actual node material registration.
		// Currently, this is a placeholder.
		// In a real implementation, you'd likely store the materialClass
		// in a map or list for lookup by name.
		trace("Node material '$name' registered.");
	}
}

// Export the class
class MeshBasicNodeMaterial {
	static public var defaultValues:MeshBasicMaterial = new MeshBasicMaterial();

	static public function new(parameters:Dynamic = null):MeshBasicNodeMaterial {
		return new MeshBasicNodeMaterial(parameters);
	}

	public function new(parameters:Dynamic = null) {
		super();

		this.isMeshBasicNodeMaterial = true;

		this.lights = false;
		//this.normals = false; @TODO: normals usage by context

		this.setDefaultValues(defaultValues);

		this.setValues(parameters);
	}

	// Placeholder for setDefaultValues and setValues
	// You'll need to implement these based on the specific behavior
	// required for the Haxe version of MeshBasicNodeMaterial.
	public function setDefaultValues(values:MeshBasicMaterial) {
		// TODO: Implement this.
	}

	public function setValues(values:Dynamic) {
		// TODO: Implement this.
	}
}

// Register the node material
NodeMaterial.addNodeMaterial("MeshBasicNodeMaterial", MeshBasicNodeMaterial);