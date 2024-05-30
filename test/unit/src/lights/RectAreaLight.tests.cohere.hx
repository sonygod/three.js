import js.QUnit;

import RectAreaLight from "../../../../src/lights/RectAreaLight.hx";

import Light from "../../../../src/lights/Light.hx";
import runStdLightTests from "../../utils/qunit-utils.hx";

class _Main {
    static function main() {
        var module = QUnit.module_("Lights");

        module.module_("RectAreaLight", () -> {
            var lights = null;

            module.beforeEach(function() {
                var parameters = {
                    color: 0xaaaaaa,
                    intensity: 0.5,
                    width: 100,
                    height: 50
                };

                lights = [
                    new RectAreaLight(parameters.color),
                    new RectAreaLight(parameters.color, parameters.intensity),
                    new RectAreaLight(parameters.color, parameters.intensity, parameters.width),
                    new RectAreaLight(parameters.color, parameters.intensity, parameters.width, parameters.height)
                ];
            });

            // INHERITANCE
            module.test_("Extending", function(assert) {
                var object = new RectAreaLight();
                assert.strictEqual(object instanceof Light, true, "RectAreaLight extends from Light");
            });

            // INSTANCING
            module.test_("Instancing", function(assert) {
                var object = new RectAreaLight();
                assert.ok(object, "Can instantiate a RectAreaLight.");
            });

            // PROPERTIES
            module.test_("type", function(assert) {
                var object = new RectAreaLight();
                assert.ok(object.type == "RectAreaLight", "RectAreaLight.type should be RectAreaLight");
            });

            module.test_("width", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            module.test_("height", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            module.test_("power", function(assert) {
                var a = new RectAreaLight(0xaaaaaa, 1, 10, 10);
                var actual = 0.;
                var expected = 0.;

                a.intensity = 100;
                actual = a.power;
                expected = 100 * a.width * a.height * Math.PI;
                assert.numEqual(actual, expected, "Correct power for an intensity of 100");

                a.intensity = 40;
                actual = a.power;
                expected = 40 * a.width * a.height * Math.PI;
                assert.numEqual(actual, expected, "Correct power for an intensity of 40");

                a.power = 100;
                actual = a.intensity;
                expected = 100 / (a.width * a.height * Math.PI);
                assert.numEqual(actual, expected, "Correct intensity for a power of 100");
            });

            // PUBLIC
            module.test_("isRectAreaLight", function(assert) {
                var object = new RectAreaLight();
                assert.ok(object.isRectAreaLight, "RectAreaLight.isRectAreaLight should be true");
            });

            module.test_("copy", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            module.test_("toJSON", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            // OTHERS
            module.test_("Standard light tests", function(assert) {
                runStdLightTests(assert, lights);
            });
        });
    }
}