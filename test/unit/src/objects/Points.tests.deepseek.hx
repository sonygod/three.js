package three.js.test.unit.src.objects;

import three.js.src.core.Object3D;
import three.js.src.materials.Material;
import three.js.src.objects.Points;

class PointsTests {

    public static function main() {
        var module = new QUnitModule("Objects");
        module.module("Points", () -> {
            QUnit.test("Extending", (assert) -> {
                var points = new Points();
                assert.strictEqual(points instanceof Object3D, true, "Points extends from Object3D");
            });

            QUnit.test("Instancing", (assert) -> {
                var object = new Points();
                assert.ok(object, "Can instantiate a Points.");
            });

            QUnit.test("type", (assert) -> {
                var object = new Points();
                assert.ok(object.type == "Points", "Points.type should be Points");
            });

            QUnit.todo("geometry", (assert) -> {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("material", (assert) -> {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.test("isPoints", (assert) -> {
                var object = new Points();
                assert.ok(object.isPoints, "Points.isPoints should be true");
            });

            QUnit.todo("copy", (assert) -> {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.test("copy/material", (assert) -> {
                var mesh1 = new Points();
                mesh1.material = [new Material()];
                var copy1 = mesh1.clone();
                assert.notStrictEqual(mesh1.material, copy1.material);

                var mesh2 = new Points();
                mesh1.material = new Material();
                var copy2 = mesh2.clone();
                assert.strictEqual(mesh2.material, copy2.material);
            });

            QUnit.todo("raycast", (assert) -> {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("updateMorphTargets", (assert) -> {
                assert.ok(false, "everything's gonna be alright");
            });
        });
    }
}