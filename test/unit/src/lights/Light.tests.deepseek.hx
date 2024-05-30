package three.js.test.unit.src.lights;

import three.js.src.core.Object3D;
import three.js.src.lights.Light;
import three.js.utils.qunit_utils.runStdLightTests;

class LightTests {

    static function main() {
        var lights:Array<Light>;

        // INHERITANCE
        function testExtending() {
            var object = new Light();
            unittest.assert(object instanceof Object3D);
        }

        // INSTANCING
        function testInstancing() {
            var object = new Light();
            unittest.assert(object != null);
        }

        // PROPERTIES
        function testType() {
            var object = new Light();
            unittest.assert(object.type == "Light");
        }

        // PUBLIC
        function testIsLight() {
            var object = new Light();
            unittest.assert(object.isLight);
        }

        function testDispose() {
            var object = new Light();
            object.dispose();
        }

        // OTHERS
        function testStandardLightTests() {
            runStdLightTests(lights);
        }

        // Run tests
        testExtending();
        testInstancing();
        testType();
        testIsLight();
        testDispose();
        testStandardLightTests();
    }
}