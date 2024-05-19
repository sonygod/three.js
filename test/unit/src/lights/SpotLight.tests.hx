package three.js.test.unit.src.lights;

import haxe.unit.TestCase;
import three.lights.SpotLight;
import three.lights.Light;
import three.test.utils.QUnitUtils;

class SpotLightTest {
    public function new() {}

    public function testExtending() {
        var object = new SpotLight(null);
        assertTrue(object instanceof Light, 'SpotLight extends from Light');
    }

    public function testInstancing() {
        var object = new SpotLight(null);
        assertNotNull(object, 'Can instantiate a SpotLight.');
    }

    public function testType() {
        var object = new SpotLight(null);
        assertEquals(object.type, 'SpotLight', 'SpotLight.type should be SpotLight');
    }

    public function testPower() {
        var a = new SpotLight(0xaaaaaa);
        a.intensity = 100;
        assertEquals(a.power, 100 * Math.PI, 'Correct power for an intensity of 100');

        a.intensity = 40;
        assertEquals(a.power, 40 * Math.PI, 'Correct power for an intensity of 40');

        a.power = 100;
        assertEquals(a.intensity, 100 / Math.PI, 'Correct intensity for a power of 100');
    }

    public function testIsSpotLight() {
        var object = new SpotLight(null);
        assertTrue(object.isSpotLight, 'SpotLight.isSpotLight should be true');
    }

    public function testDispose() {
        var object = new SpotLight(null);
        object.dispose();
        // ensure calls dispose() on shadow
    }

    public function testStandardLightTests() {
        var lights = [
            new SpotLight(0xaaaaaa),
            new SpotLight(0xaaaaaa, 0.5),
            new SpotLight(0xaaaaaa, 0.5, 100),
            new SpotLight(0xaaaaaa, 0.5, 100, 0.8),
            new SpotLight(0xaaaaaa, 0.5, 100, 0.8, 8),
            new SpotLight(0xaaaaaa, 0.5, 100, 0.8, 8, 2)
        ];
        QUnitUtils.runStdLightTests(lights);
    }

    static function main() {
        var testCase = new SpotLightTest();
        testCase.testExtending();
        testCase.testInstancing();
        testCase.testType();
        testCase.testPower();
        testCase.testIsSpotLight();
        testCase.testDispose();
        testCase.testStandardLightTests();
    }
}