import js.three.Mesh;
import js.geometries.InstancedPointsGeometry;
import js.nodes.materials.InstancedPointsNodeMaterial;

class InstancedPoints extends Mesh {
    public function new(geometry:InstancedPointsGeometry = InstancedPointsGeometry(), material:InstancedPointsNodeMaterial = InstancedPointsNodeMaterial()) {
        super(geometry, material);
        this.isInstancedPoints = true;
        this.setType('InstancedPoints');
    }
}