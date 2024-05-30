package three.js.test.unit.src.core;

import three.js.core.Uniform;
import three.js.math.Vector3;
import three.js.utils.mathConstants;

class UniformTests {
    public static function new() {
        QUnit.module("Core", () => {
            QUnit.module("Uniform", () => {
                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var a:Uniform;
                    var b:Vector3 = new Vector3(mathConstants.x, mathConstants.y, mathConstants.z);

                    a = new Uniform(5);
                    assert.strictEqual(a.value, 5, 'New constructor works with simple values');

                    a = new Uniform(b);
                    assertTrue(a.value.equals(b), 'New constructor works with complex values');
                });

                // PROPERTIES
                QUnit.todo("value", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("clone", (assert) -> {
                    var a:Uniform = new Uniform(23);
                    var b:Uniform = a.clone();

                    assert.strictEqual(b.value, a.value, 'clone() with simple values works');

                    a = new Uniform(new Vector3(1, 2, 3));
                    b = a.clone();

                    assertTrue(b.value.equals(a.value), 'clone() with complex values works');
                });
            });
        });
    }
}