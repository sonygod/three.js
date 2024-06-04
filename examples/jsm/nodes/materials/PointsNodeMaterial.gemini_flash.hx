import three.materials.PointsMaterial;
import three.materials.Material;
import three.nodes.NodeMaterial;

class PointsNodeMaterial extends NodeMaterial {

	public var sizeNode:Dynamic = null;

	public function new(parameters:Dynamic = null) {
		super();

		this.lights = false;
		this.normals = false;
		this.transparent = true;

		this.setDefaultValues(new PointsMaterial());

		if (parameters != null) {
			this.setValues(parameters);
		}
	}

	public function copy(source:PointsNodeMaterial):PointsNodeMaterial {
		this.sizeNode = source.sizeNode;
		return super.copy(source);
	}

	static public function addNodeMaterial():Void {
		NodeMaterial.addNodeMaterial("PointsNodeMaterial", PointsNodeMaterial);
	}
}

PointsNodeMaterial.addNodeMaterial();