// Haxe doesn't have direct equivalent for QUnit, so we will use Haxe.unit library
import haxe.unit.TestCase;

// Importing necessary classes
import three.src.helpers.PointLightHelper;
import three.src.objects.Mesh;
import three.src.lights.PointLight;

// Defining PointLightHelperTest class
class PointLightHelperTest {

    // Defining test parameters
    private var parameters:Dynamic = {
        sphereSize: 1,
        color: 0xaaaaaa,
        intensity: 0.5,
        distance: 100,
        decay: 2
    };

    // Creating a new test case
    public function new() {
        var testCase = new TestCase();

        // INHERITANCE
        testCase.add("Extending", function(assert) {
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            assert.equals(Std.is(object, Mesh), true, "PointLightHelper extends from Mesh");
        });

        // INSTANCING
        testCase.add("Instancing", function(assert) {
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            assert.notNull(object, "Can instantiate a PointLightHelper.");
        });

        // PROPERTIES
        testCase.add("type", function(assert) {
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            assert.equals(object.type, "PointLightHelper", "PointLightHelper.type should be PointLightHelper");
        });

        // PUBLIC
        testCase.add("dispose", function(assert) {
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            object.dispose();
            assert.pass("dispose method executed without errors");
        });

        // Returning the test case
        return testCase;
    }
}