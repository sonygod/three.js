import NodeMaterial from "./NodeMaterial";
import three.materials.MeshBasicMaterial;

class MeshBasicNodeMaterial extends NodeMaterial {

	public var isMeshBasicNodeMaterial:Bool = true;

	public var lights:Bool = false;
	//public var normals:Bool = false; // @TODO: normals usage by context

	public function new(parameters:Dynamic = null) {
		super();

		this.setDefaultValues(new MeshBasicMaterial());
		if (parameters != null) {
			this.setValues(parameters);
		}
	}
}

NodeMaterial.addNodeMaterial("MeshBasicNodeMaterial", MeshBasicNodeMaterial);