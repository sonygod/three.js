import qunit.QUnit;
import three.core.Object3D;
import three.materials.Material;
import three.objects.Points;

class PointsTests {
    public static function main() {
        QUnit.module("Objects", () -> {
            QUnit.module("Points", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var points:Points = new Points();
                    assert.strictEqual(Std.is(points, Object3D), true, "Points extends from Object3D");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var obj:Points = new Points();
                    assert.ok(obj != null, "Can instantiate a Points.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var obj:Points = new Points();
                    assert.ok(obj.type == "Points", "Points.type should be Points");
                });

                // PUBLIC
                QUnit.test("isPoints", (assert) -> {
                    var obj:Points = new Points();
                    assert.ok(obj.isPoints, "Points.isPoints should be true");
                });

                QUnit.test("copy/material", (assert) -> {
                    // Material arrays are cloned
                    var mesh1:Points = new Points();
                    mesh1.material = [new Material()];

                    var copy1:Points = mesh1.clone();
                    assert.notStrictEqual(mesh1.material, copy1.material);

                    // Non arrays are not cloned
                    var mesh2:Points = new Points();
                    mesh2.material = new Material();
                    var copy2:Points = mesh2.clone();
                    assert.strictEqual(mesh2.material, copy2.material);
                });
            });
        });
    }
}