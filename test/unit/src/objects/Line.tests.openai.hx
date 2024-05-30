package three.test.unit.objects;

import three.objects.Line;
import three.core.Object3D;
import three.materials.Material;

class LineTests {
  public function new() {}

  public static function main() {
    QUnit.module("Objects", () => {
      QUnit.module("Line", () => {
        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var line = new Line();
          assert.isTrue(line instanceof Object3D, 'Line extends from Object3D');
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object = new Line();
          assert.truthy(object, 'Can instantiate a Line.');
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object = new Line();
          assert.equal(object.type, 'Line', 'Line.type should be Line');
        });

        QUnit.todo("geometry", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        QUnit.todo("material", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isLine", (assert) => {
          var object = new Line();
          assert.isTrue(object.isLine, 'Line.isLine should be true');
        });

        QUnit.todo("copy", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        QUnit.test("copy/material", (assert) => {
          // Material arrays are cloned
          var mesh1 = new Line();
          mesh1.material = [new Material()];

          var copy1 = mesh1.clone();
          assert.notEqual(mesh1.material, copy1.material);

          // Non arrays are not cloned
          var mesh2 = new Line();
          mesh2.material = new Material();
          var copy2 = mesh2.clone();
          assert.equal(mesh2.material, copy2.material);
        });

        QUnit.todo("computeLineDistances", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        QUnit.todo("raycast", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        QUnit.todo("updateMorphTargets", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        QUnit.todo("clone", (assert) => {
          // inherited from Object3D, test instance specific behaviour.
          assert.fail("everything's gonna be alright");
        });
      });
    });
  }
}