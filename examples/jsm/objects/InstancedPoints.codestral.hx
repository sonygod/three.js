import three.Mesh;
import three.geometries.InstancedPointsGeometry;
import three.nodes.materials.InstancedPointsNodeMaterial;

class InstancedPoints extends Mesh {

    public function new(geometry:InstancedPointsGeometry = new InstancedPointsGeometry(), material:InstancedPointsNodeMaterial = new InstancedPointsNodeMaterial()) {
        super(geometry, material);

        this.isInstancedPoints = true;
        this.type = 'InstancedPoints';
    }
}