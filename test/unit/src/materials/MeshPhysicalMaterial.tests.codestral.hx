import js.Browser.document;
import qunit.QUnit;
import three.src.materials.MeshPhysicalMaterial;
import three.src.materials.Material;

class MeshPhysicalMaterialTests {
  public static function main() {
    QUnit.module("Materials", () -> {
      QUnit.module("MeshPhysicalMaterial", () -> {
        // INHERITANCE
        QUnit.test("Extending", assert -> {
          var object = new MeshPhysicalMaterial();
          assert.strictEqual(Std.is(object, Material), true, 'MeshPhysicalMaterial extends from Material');
        });

        // INSTANCING
        QUnit.test("Instancing", assert -> {
          var object = new MeshPhysicalMaterial();
          assert.ok(object, 'Can instantiate a MeshPhysicalMaterial.');
        });

        // PROPERTIES
        QUnit.todo("defines", assert -> {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test("type", assert -> {
          var object = new MeshPhysicalMaterial();
          assert.ok(object.type == "MeshPhysicalMaterial", 'MeshPhysicalMaterial.type should be MeshPhysicalMaterial');
        });

        QUnit.todo("clearcoatMap", assert -> {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        //... continue with the rest of the tests in the same manner

        // PUBLIC
        QUnit.test("isMeshPhysicalMaterial", assert -> {
          var object = new MeshPhysicalMaterial();
          assert.ok(object.isMeshPhysicalMaterial, 'MeshPhysicalMaterial.isMeshPhysicalMaterial should be true');
        });

        QUnit.todo("copy", assert -> {
          assert.ok(false, 'everything\'s gonna be alright');
        });
      });
    });
  }
}