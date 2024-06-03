import qunit.QUnit;
import three.lights.LightShadow;
import three.cameras.OrthographicCamera;
import three.math.Vector2;

class LightShadowTests {
    public function new() {
        QUnit.module("Lights", () -> {
            QUnit.module("LightShadow", () -> {
                QUnit.test("Instancing", (assert) -> {
                    var camera = new OrthographicCamera(-5, 5, 5, -5, 0.5, 500);
                    var obj = new LightShadow(camera);
                    assert.isTrue(obj != null, "Can instantiate a LightShadow.");
                });

                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);
                    var obj = new LightShadow();
                    obj.dispose();
                });

                QUnit.test("clone/copy", (assert) -> {
                    var a = new LightShadow(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
                    var b = new LightShadow(new OrthographicCamera(-3, 3, 3, -3, 0.3, 300));
                    assert.notEqual(a, b, "Newly instanced shadows are not equal");

                    var c = a.clone();
                    assert.equal(a, c, "Shadows are identical after clone()");

                    c.mapSize.set(256, 256);
                    assert.notEqual(a, c, "Shadows are different again after change");

                    b.copy(a);
                    assert.equal(a, b, "Shadows are identical after copy()");

                    b.mapSize.set(512, 512);
                    assert.notEqual(a, b, "Shadows are different again after change");
                });
            });
        });
    }
}