import js.QUnit.*;
import js.QUnit.QUnitTest;

import js.Three.Object3D;
import js.Three.Light;

import js.Three.tests.qunit.utils.qunit_utils.runStdLightTests;

class _Main {
    static function main() {
        module("Lights", {
            setup: function() {
                trace("Lights module setup");
            },
            teardown: function() {
                trace("Lights module teardown");
            }
        });

        module("Light", {
            setup: function() {
                trace("Light module setup");
                var parameters = {
                    color: 0xaaaaaa,
                    intensity: 0.5
                };

                lights = [
                    new Light(),
                    new Light(parameters.color),
                    new Light(parameters.color, parameters.intensity)
                ];
            },
            teardown: function() {
                trace("Light module teardown");
            }
        });

        // INHERITANCE
        test("Extending", function(assert) {
            var object = new Light();
            assert.strictEqual(object instanceof Object3D, true, "Light extends from Object3D");
        });

        // INSTANCING
        test("Instancing", function(assert) {
            var object = new Light();
            assert.ok(object, "Can instantiate a Light.");
        });

        // PROPERTIES
        test("type", function(assert) {
            var object = new Light();
            assert.ok(object.type == "Light", "Light.type should be Light");
        });

        test("color", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        test("intensity", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        test("isLight", function(assert) {
            var object = new Light();
            assert.ok(object.isLight, "Light.isLight should be true");
        });

        test("dispose", function(assert) {
            assert.expect(0);
            var object = new Light();
            object.dispose();
        });

        test("copy", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        test("toJSON", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        test("Standard light tests", function(assert) {
            runStdLightTests(assert, lights);
        });
    }
}