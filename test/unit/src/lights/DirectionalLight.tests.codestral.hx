import three.lights.DirectionalLight;
import three.lights.Light;
import test.qunit.QUnit;
import utils.qunit.StdLightTests;

class DirectionalLightTests {

    static var lights: Array<Light> = [];

    static function beforeEach() {
        var parameters = {
            color: 0xaaaaaa,
            intensity: 0.8
        };

        lights = [
            new DirectionalLight(),
            new DirectionalLight(parameters.color),
            new DirectionalLight(parameters.color, parameters.intensity)
        ];
    }

    static function testExtending(assert: Assert) {
        var object = new DirectionalLight();
        assert.isTrue(Std.is(object, Light), "DirectionalLight extends from Light");
    }

    static function testInstancing(assert: Assert) {
        var object = new DirectionalLight();
        assert.isNotNull(object, "Can instantiate a DirectionalLight.");
    }

    static function testType(assert: Assert) {
        var object = new DirectionalLight();
        assert.isTrue(object.type == "DirectionalLight", "DirectionalLight.type should be DirectionalLight");
    }

    static function testIsDirectionalLight(assert: Assert) {
        var object = new DirectionalLight();
        assert.isTrue(object.isDirectionalLight, "DirectionalLight.isDirectionalLight should be true");
    }

    static function testDispose(assert: Assert) {
        var object = new DirectionalLight();
        object.dispose();
        // ensure calls dispose() on shadow
    }

    static function testStandardLightTests(assert: Assert) {
        StdLightTests.run(assert, lights);
    }
}

QUnit.module("Lights", () => {
    QUnit.module("DirectionalLight", () => {
        QUnit.beforeEach(DirectionalLightTests.beforeEach);

        QUnit.test("Extending", DirectionalLightTests.testExtending);
        QUnit.test("Instancing", DirectionalLightTests.testInstancing);
        QUnit.test("type", DirectionalLightTests.testType);
        QUnit.test("isDirectionalLight", DirectionalLightTests.testIsDirectionalLight);
        QUnit.test("dispose", DirectionalLightTests.testDispose);
        QUnit.test("Standard light tests", DirectionalLightTests.testStandardLightTests);
    });
});