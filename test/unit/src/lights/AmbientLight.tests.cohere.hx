import js.QUnit;
import js.AmbientLight;
import js.Light;
import js.runStdLightTests;

class _Main {
    static function main() {
        var lights:Array<AmbientLight>;

        var parameters = { color: 0xaaaaaa, intensity: 0.5 };

        lights = [
            new AmbientLight(),
            new AmbientLight(parameters.color),
            new AmbientLight(parameters.color, parameters.intensity)
        ];

        // INHERITANCE
        QUnit.test("Extending", function() {
            var object = new AmbientLight();
            QUnit.strictEqual(object instanceof Light, true, "AmbientLight extends from Light");
        });

        // INSTANCING
        QUnit.test("Instancing", function() {
            var object = new AmbientLight();
            QUnit.ok(object, "Can instantiate an AmbientLight.");
        });

        // PROPERTIES
        QUnit.test("type", function() {
            var object = new AmbientLight();
            QUnit.ok(object.type == "AmbientLight", "AmbientLight.type should be AmbientLight");
        });

        // PUBLIC
        QUnit.test("isAmbientLight", function() {
            var object = new AmbientLight();
            QUnit.ok(object.isAmbientLight, "AmbientLight.isAmbientLight should be true");
        });

        // OTHERS
        QUnit.test("Standard light tests", function() {
            runStdLightTests(lights);
        });
    }
}