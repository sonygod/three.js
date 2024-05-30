package three.test.unit.src.objects;

import three.core.Object3D;
import three.materials.Material;
import three.objects.Points;

class PointsTests {

    public function new() {
    }

    public static function main() {
        // INHERITANCE
        QUnit.module("Objects", () => {
            QUnit.module("Points", () => {

                QUnit.test("Extending", (assert) => {
                    var points = new Points();
                    assert.isTrue(points instanceof Object3D, 'Points extends from Object3D');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new Points();
                    assert.ok(object, 'Can instantiate a Points.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new Points();
                    assert.ok(object.type == 'Points', 'Points.type should be Points');
                });

                QUnit.todo("geometry", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("material", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test("isPoints", (assert) => {
                    var object = new Points();
                    assert.ok(object.isPoints, 'Points.isPoints should be true');
                });

                QUnit.todo("copy", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test("copy/material", (assert) => {
                    // Material arrays are cloned
                    var mesh1 = new Points();
                    mesh1.material = [new Material()];

                    var copy1 = mesh1.clone();
                    assert.notStrictEqual(mesh1.material, copy1.material);

                    // Non arrays are not cloned
                    var mesh2 = new Points();
                    mesh1.material = new Material();
                    var copy2 = mesh2.clone();
                    assert.strictEqual(mesh2.material, copy2.material);
                });

                QUnit.todo("raycast", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("updateMorphTargets", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

            });
        });
    }
}