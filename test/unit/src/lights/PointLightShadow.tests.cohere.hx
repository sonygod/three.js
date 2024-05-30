import js.QUnit;

import js.PointLightShadow from "../../../../src/lights/PointLightShadow.js";
import js.LightShadow from "../../../../src/lights/LightShadow.js";

class PointLightShadowTest {
    static function main() {
        QUnit.module("Lights", {
            setup:function() {
            },
            teardown:function() {
            }
        }, function() {
            QUnit.module("PointLightShadow", {
                setup:function() {
                },
                teardown:function() {
                }
            }, function() {
                // INHERITANCE
                QUnit.test("Extending", function(assert) {
                    var object = new PointLightShadow();
                    assert.strictEqual(Std.is(object, LightShadow), true, "PointLightShadow extends from LightShadow");
                });

                // INSTANCING
                QUnit.test("Instancing", function(assert) {
                    var object = new PointLightShadow();
                    assert.ok(object, "Can instantiate a PointLightShadow.");
                });

                // PUBLIC
                QUnit.test("isPointLightShadow", function(assert) {
                    var object = new PointLightShadow();
                    assert.ok(object.isPointLightShadow, "PointLightShadow.isPointLightShadow should be true");
                });

                QUnit.todo("updateMatrices", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}

PointLightShadowTest.main();