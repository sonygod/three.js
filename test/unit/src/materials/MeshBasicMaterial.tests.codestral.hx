import three.materials.MeshBasicMaterial;
import three.materials.Material;

class MeshBasicMaterialTests {
    public function new() {
        testExtending();
        testInstancing();
        testType();
        testIsMeshBasicMaterial();
    }

    private function testExtending() {
        var object = new MeshBasicMaterial();
        haxe.unit.Assert.isTrue(object is Material, "MeshBasicMaterial extends from Material");
    }

    private function testInstancing() {
        var object = new MeshBasicMaterial();
        haxe.unit.Assert.isNotNull(object, "Can instantiate a MeshBasicMaterial.");
    }

    private function testType() {
        var object = new MeshBasicMaterial();
        haxe.unit.Assert.isTrue(object.type == "MeshBasicMaterial", "MeshBasicMaterial.type should be MeshBasicMaterial");
    }

    private function testIsMeshBasicMaterial() {
        var object = new MeshBasicMaterial();
        haxe.unit.Assert.isTrue(object.isMeshBasicMaterial, "MeshBasicMaterial.isMeshBasicMaterial should be true");
    }
}