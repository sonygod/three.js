// Haxe doesn't have a QUnit equivalent, so we'll use haxe.unit for testing.
import haxe.unit.TestCase;

// Importing the Light class from the src/lights/Light.hx file.
import three.lights.Light;

// Importing the Object3D class from the src/core/Object3D.hx file.
import three.core.Object3D;

// Importing the runStdLightTests function from the utils/qunit-utils.hx file.
import utils.QUnitUtils.runStdLightTests;

// Defining the LightTests class that extends haxe.unit.TestCase.
class LightTests extends TestCase {

    var lights:Array<Light> = null;

    // The setup function is called before each test.
    override function setup() {
        var parameters = {
            color: 0xaaaaaa,
            intensity: 0.5
        };

        lights = [
            new Light(),
            new Light(parameters.color),
            new Light(parameters.color, parameters.intensity)
        ];
    }

    // Test for extending from Object3D.
    public function testExtending():Void {
        var object = new Light();
        assertTrue(Std.is(object, Object3D), "Light extends from Object3D");
    }

    // Test for instantiating a Light.
    public function testInstancing():Void {
        var object = new Light();
        assertNotNull(object, "Can instantiate a Light.");
    }

    // Test for the type property.
    public function testType():Void {
        var object = new Light();
        assertEquals(object.type, "Light", "Light.type should be Light");
    }

    // Test for the isLight property.
    public function testIsLight():Void {
        var object = new Light();
        assertTrue(object.isLight, "Light.isLight should be true");
    }

    // Test for the dispose method.
    public function testDispose():Void {
        var object = new Light();
        object.dispose();
        // Currently, there's no way to assert that a function executed without errors in Haxe.
    }

    // Test for the standard light tests.
    public function testStandardLightTests():Void {
        runStdLightTests(this, lights);
    }
}