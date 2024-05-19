package three.lights;

import haxe.unit.TestCase;
import three.lights.AmbientLight;
import three.lights.Light;

class AmbientLightTests {

    public static function main() {
        var testCase = new AmbientLightTests();
        testCase.testExtending();
        testCase.testInstancing();
        testCase.testType();
        testCase.testIsAmbientLight();
        testCase.testStandardLightTests();
    }

    public function new() {}

    public function testExtending() {
        var object = new AmbientLight();
        assertTrue(object instanceof Light, 'AmbientLight extends from Light');
    }

    public function testInstancing() {
        var object = new AmbientLight();
        assertNotNull(object, 'Can instantiate an AmbientLight.');
    }

    public function testType() {
        var object = new AmbientLight();
        assertEquals(object.type, 'AmbientLight', 'AmbientLight.type should be AmbientLight');
    }

    public function testIsAmbientLight() {
        var object = new AmbientLight();
        assertTrue(object.isAmbientLight, 'AmbientLight.isAmbientLight should be true');
    }

    public function testStandardLightTests() {
        var lights = [
            new AmbientLight(),
            new AmbientLight(0xaaaaaa),
            new AmbientLight(0xaaaaaa, 0.5)
        ];
        runStdLightTests(lights);
    }
}

class RunStdLightTests {
    public static function runStdLightTests(lights:Array<AmbientLight>) {
        // implement the runStdLightTests function here
    }
}