import three.Mesh;
import three.examples.jsm.geometries.InstancedPointsGeometry;
import three.examples.jsm.nodes.materials.InstancedPointsNodeMaterial;

class InstancedPoints extends Mesh {

	public function new(geometry:InstancedPointsGeometry = new InstancedPointsGeometry(), material:InstancedPointsNodeMaterial = new InstancedPointsNodeMaterial()) {
		super(geometry, material);
		this.isInstancedPoints = true;
		this.type = 'InstancedPoints';
	}

}

typedef InstancedPoints_three = js.Browser.window.three.InstancedPoints;

@:native("three.InstancedPoints")
extern class InstancedPoints extends Mesh {

	public function new(geometry:InstancedPointsGeometry = new InstancedPointsGeometry(), material:InstancedPointsNodeMaterial = new InstancedPointsNodeMaterial());

}