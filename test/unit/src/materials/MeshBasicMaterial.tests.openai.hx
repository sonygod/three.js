import Materials.MeshBasicMaterial;
import Materials.Material;

class MeshBasicMaterialTests {
  public static function main() {
    haxe.unit.TestRunner.runTests([
      new MeshBasicMaterialTest()
    ]);
  }
}

class MeshBasicMaterialTest extends haxe.unit.TestCase {
  function testExtending() {
    var object = new MeshBasicMaterial();
    assertTrue)object instanceof Material, "MeshBasicMaterial extends from Material";
  }

  function testInstancing() {
    var object = new MeshBasicMaterial();
    assertTrue(object != null, "Can instantiate a MeshBasicMaterial.");
  }

  function testType() {
    var object = new MeshBasicMaterial();
    assertEquals("MeshBasicMaterial", object.type, "MeshBasicMaterial.type should be MeshBasicMaterial");
  }

  function testColor() {
    // todo
    assertTrue(false, "everything's gonna be alright");
  }

  function testMap() {
    // todo
    assertTrue(false, "everything's gonna be alright");
  }

  // ... (rest of the todo tests)

  function testIsMeshBasicMaterial() {
    var object = new MeshBasicMaterial();
    assertTrue(object.isMeshBasicMaterial, "MeshBasicMaterial.isMeshBasicMaterial should be true");
  }

  function testCopy() {
    // todo
    assertTrue(false, "everything's gonna be alright");
  }
}