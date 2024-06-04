import three.core.Mesh;
import geometries.InstancedPointsGeometry;
import nodes.materials.InstancedPointsNodeMaterial;

class InstancedPoints extends Mesh {

	public function new(geometry:InstancedPointsGeometry = new InstancedPointsGeometry(), material:InstancedPointsNodeMaterial = new InstancedPointsNodeMaterial()) {
		super(geometry, material);

		this.isInstancedPoints = true;
		this.type = "InstancedPoints";
	}

	public var isInstancedPoints:Bool;
	public var type:String;
}