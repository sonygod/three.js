import js.QUnit.*;
import js.QUnit.QUnitTest;

import js.Three.Lights.HemisphereLight;
import js.Three.Lights.Light;
import js.Three.Utils.QunitUtils.runStdLightTests;

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

        module("HemisphereLight", {
            setup: function() {
                trace("HemisphereLight module setup");
                var parameters = {
                    skyColor: 0x123456,
                    groundColor: 0xabc012,
                    intensity: 0.6
                };

                lights = [
                    new HemisphereLight(),
                    new HemisphereLight(parameters.skyColor),
                    new HemisphereLight(parameters.skyColor, parameters.groundColor),
                    new HemisphereLight(parameters.skyColor, parameters.groundColor, parameters.intensity)
                ];
            },
            teardown: function() {
                trace("HemisphereLight module teardown");
            }
        });

        // INHERITANCE
        test("Extending", function() {
            var object = new HemisphereLight();
            ok(object instanceof Light, "HemisphereLight extends from Light");
        });

        // INSTANCING
        test("Instancing", function() {
            var object = new HemisphereLight();
            ok(object, "Can instantiate a HemisphereLight.");
        });

        // PROPERTIES
        test("type", function() {
            var object = new HemisphereLight();
            ok(object.type == "HemisphereLight", "HemisphereLight.type should be HemisphereLight");
        });

        test("position", function() {
            ok(false, "everything's gonna be alright");
        });

        test("groundColor", function() {
            ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        test("isHemisphereLight", function() {
            var object = new HemisphereLight();
            ok(object.isHemisphereLight, "HemisphereLight.isHemisphereLight should be true");
        });

        test("copy", function() {
            ok(false, "everything's gonna be alright");
        });

        // OTHERS
        test("Standard light tests", function() {
            runStdLightTests(assert, lights);
        });
    }
}