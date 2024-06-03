import three.materials.MeshPhongMaterial;
import three.materials.Material;

class MeshPhongMaterialTests {
    public function new() {
        // INHERITANCE
        var object: MeshPhongMaterial = new MeshPhongMaterial();
        trace(Std.is(object, Material), 'MeshPhongMaterial extends from Material');

        // INSTANCING
        var object: MeshPhongMaterial = new MeshPhongMaterial();
        trace(object != null, 'Can instantiate a MeshPhongMaterial.');

        // PROPERTIES
        var object: MeshPhongMaterial = new MeshPhongMaterial();
        trace(object.type == 'MeshPhongMaterial', 'MeshPhongMaterial.type should be MeshPhongMaterial');

        // TODO: Implement other properties

        // PUBLIC
        var object: MeshPhongMaterial = new MeshPhongMaterial();
        trace(object.isMeshPhongMaterial(), 'MeshPhongMaterial.isMeshPhongMaterial should be true');

        // TODO: Implement other public methods
    }
}