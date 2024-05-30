package lights;

import js.QUnit;

import lights.DirectionalLight;
import lights.Light;
import utils.qunit_utils.runStdLightTests;

class DirectionalLightTest {
    static function extend() {
        var object = new DirectionalLight();
        QUnit.strictEqual(Std.is(object, Light), true, 'DirectionalLight extends from Light');
    }

    static function instantiate() {
        var object = new DirectionalLight();
        QUnit.ok(object, 'Can instantiate a DirectionalLight.');
    }

    static function type() {
        var object = new DirectionalLight();
        QUnit.ok(object.type == 'DirectionalLight', 'DirectionalLight.type should be DirectionalLight');
    }

    static function isDirectionalLight() {
        var object = new DirectionalLight();
        QUnit.ok(object.isDirectionalLight, 'DirectionalLight.isDirectionalLight should be true');
    }

    static function dispose() {
        var object = new DirectionalLight();
        object.dispose();
    }

    static function standardLightTests() {
        var lights = [
            new DirectionalLight(),
            new DirectionalLight(0xaaaaaa),
            new DirectionalLight(0xaaaaaa, 0.8)
        ];
        runStdLightTests(lights);
    }
}

@:build(DirectionalLightTest.extend)
@:build(DirectionalLightTest.instantiate)
@:build(DirectionalLightTest.type)
@:build(DirectionalLightTest.isDirectionalLight)
@:build(DirectionalLightTest.dispose)
@:build(DirectionalLightTest.standardLightTests)
class DirectionalLightModule {
}