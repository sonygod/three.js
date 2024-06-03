import three.materials.MeshToonMaterial;
import three.materials.Material;

class MeshToonMaterialTests {

    public function testExtending(): Void {
        var object: MeshToonMaterial = new MeshToonMaterial();
        trace("MeshToonMaterial extends from Material: " + (object is Material));
    }

    public function testInstancing(): Void {
        var object: MeshToonMaterial = new MeshToonMaterial();
        trace("Can instantiate a MeshToonMaterial: " + (object != null));
    }

    public function testType(): Void {
        var object: MeshToonMaterial = new MeshToonMaterial();
        trace("MeshToonMaterial.type should be MeshToonMaterial: " + (object.type == "MeshToonMaterial"));
    }

    public function testIsMeshToonMaterial(): Void {
        var object: MeshToonMaterial = new MeshToonMaterial();
        trace("MeshToonMaterial.isMeshToonMaterial should be true: " + object.isMeshToonMaterial);
    }
}