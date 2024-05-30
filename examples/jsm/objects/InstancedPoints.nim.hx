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


Please note that the Haxe code assumes that the `three` package is properly imported and set up in your project. Also, the Haxe code does not include the `export default` statement, as Haxe does not have a direct equivalent to this JavaScript feature. Instead, you can use the `@:expose` metadata tag to make the class available for external use.

Here's an example of how to use the `@:expose` metadata tag:

@:expose
class InstancedPoints extends Mesh {
    // ...
}