import three.scenes.Fog;
import qunit.QUnit;

class FogTests {
    public static function main() {
        QUnit.module("Scenes", () -> {
            QUnit.module("Fog", () -> {
                QUnit.test("Instancing", (assert: QUnit.Assert) -> {
                    // no params
                    var object: Fog = new Fog();
                    assert.ok(object, "Can instantiate a Fog.");

                    // color
                    var object_color: Fog = new Fog(0xffffff);
                    assert.ok(object_color, "Can instantiate a Fog with color.");

                    // color, near, far
                    var object_all: Fog = new Fog(0xffffff, 0.015, 100);
                    assert.ok(object_all, "Can instantiate a Fog with color, near, far.");
                });

                QUnit.test("isFog", (assert: QUnit.Assert) -> {
                    var object: Fog = new Fog();
                    assert.ok(object.isFog, "Fog.isFog should be true");
                });
            });
        });
    }
}

FogTests.main();