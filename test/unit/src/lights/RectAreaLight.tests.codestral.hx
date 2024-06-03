import qunit.QUnitModule;
import qunit.QUnitTest;
import js.Browser.document;
import three.lights.RectAreaLight;
import three.lights.Light;
import qunitUtils.runStdLightTests;

class RectAreaLightTests {

    private static var lights: Array<RectAreaLight>;

    @:beforeEach
    public static function beforeEach() {
        var parameters = {
            color: 0xaaaaaa,
            intensity: 0.5,
            width: 100,
            height: 50
        };

        lights = [
            new RectAreaLight(parameters.color),
            new RectAreaLight(parameters.color, parameters.intensity),
            new RectAreaLight(parameters.color, parameters.intensity, parameters.width),
            new RectAreaLight(parameters.color, parameters.intensity, parameters.width, parameters.height)
        ];
    }

    @:QUnitModule("Lights")
    public static function lightsModule() {
        @:QUnitModule("RectAreaLight")
        public static function rectAreaLightModule() {

            // INHERITANCE
            @:QUnitTest("Extending")
            public static function extending(assert: qunit.Assert) {
                var object = new RectAreaLight();
                assert.isTrue(
                    js.Std.is(object, Light),
                    'RectAreaLight extends from Light'
                );
            }

            // INSTANCING
            @:QUnitTest("Instancing")
            public static function instancing(assert: qunit.Assert) {
                var object = new RectAreaLight();
                assert.isNotNull(object, 'Can instantiate a RectAreaLight.');
            }

            // PROPERTIES
            @:QUnitTest("type")
            public static function type(assert: qunit.Assert) {
                var object = new RectAreaLight();
                assert.isTrue(
                    object.type == 'RectAreaLight',
                    'RectAreaLight.type should be RectAreaLight'
                );
            }

            @:QUnitTest("power")
            public static function power(assert: qunit.Assert) {
                var a = new RectAreaLight(0xaaaaaa, 1, 10, 10);
                var actual: Float;
                var expected: Float;

                a.intensity = 100;
                actual = a.power;
                expected = 100 * a.width * a.height * Math.PI;
                assert.numEqual(actual, expected, 'Correct power for an intensity of 100');

                a.intensity = 40;
                actual = a.power;
                expected = 40 * a.width * a.height * Math.PI;
                assert.numEqual(actual, expected, 'Correct power for an intensity of 40');

                a.power = 100;
                actual = a.intensity;
                expected = 100 / (a.width * a.height * Math.PI);
                assert.numEqual(actual, expected, 'Correct intensity for a power of 100');
            }

            // PUBLIC
            @:QUnitTest("isRectAreaLight")
            public static function isRectAreaLight(assert: qunit.Assert) {
                var object = new RectAreaLight();
                assert.isTrue(
                    object.isRectAreaLight,
                    'RectAreaLight.isRectAreaLight should be true'
                );
            }

            // OTHERS
            @:QUnitTest("Standard light tests")
            public static function standardLightTests(assert: qunit.Assert) {
                runStdLightTests(assert, lights);
            }
        }
    }
}