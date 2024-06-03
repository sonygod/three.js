import qunit.QUnit;
import three.src.lights.PointLightShadow;
import three.src.lights.LightShadow;

QUnit.module("Lights", () -> {
    QUnit.module("PointLightShadow", () -> {
        // INHERITANCE
        QUnit.test("Extending", (assert) -> {
            var object:PointLightShadow = new PointLightShadow();
            assert.strictEqual(Std.is(object, LightShadow), true, "PointLightShadow extends from LightShadow");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) -> {
            var object:PointLightShadow = new PointLightShadow();
            assert.ok(object, "Can instantiate a PointLightShadow.");
        });

        // PUBLIC
        QUnit.test("isPointLightShadow", (assert) -> {
            var object:PointLightShadow = new PointLightShadow();
            assert.ok(object.isPointLightShadow, "PointLightShadow.isPointLightShadow should be true");
        });

        // TODO: Uncomment this block when the updateMatrices method is implemented
        /*QUnit.todo("updateMatrices", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });*/
    });
});