package three.lights;

import haxe.unit.TestCase;

class PointLightTests {

    public function new() {}

    public static function main() {
        TestCase.createTestSuite(PointLightTests);
    }

    @Before
    public function beforeEach() {
        var parameters = {
            color: 0xaaaaaa,
            intensity: 0.5,
            distance: 100,
            decay: 2
        };
        lights = [
            new PointLight(),
            new PointLight(parameters.color),
            new PointLight(parameters.color, parameters.intensity),
            new PointLight(parameters.color, parameters.intensity, parameters.distance),
            new PointLight(parameters.color, parameters.intensity, parameters.distance, parameters.decay)
        ];
    }

    // INHERITANCE
    @Test
    public function testExtending() {
        var object = new PointLight();
        assertTrue(object instanceof Light, 'PointLight extends from Light');
    }

    // INSTANCING
    @Test
    public function testInstancing() {
        var object = new PointLight();
        assertNotNull(object, 'Can instantiate a PointLight.');
    }

    // PROPERTIES
    @Test
    public function testType() {
        var object = new PointLight();
        assertEquals(object.type, 'PointLight', 'PointLight.type should be PointLight');
    }

    @Test
    public function testDistance() {
        TODO('everything\'s gonna be alright');
    }

    @Test
    public function testDecay() {
        TODO('everything\'s gonna be alright');
    }

    @Test
    public function testShadow() {
        TODO('everything\'s gonna be alright');
    }

    @Test
    public function testPower() {
        var a = new PointLight(0xaaaaaa);
        a.intensity = 100;
        assertEquals(a.power, 100 * Math.PI * 4, 'Correct power for an intensity of 100');
        a.intensity = 40;
        assertEquals(a.power, 40 * Math.PI * 4, 'Correct power for an intensity of 40');
        a.power = 100;
        assertEquals(a.intensity, 100 / (4 * Math.PI), 'Correct intensity for a power of 100');
    }

    // PUBLIC
    @Test
    public function testIsPointLight() {
        var object = new PointLight();
        assertTrue(object.isPointLight, 'PointLight.isPointLight should be true');
    }

    @Test
    public function testDispose() {
        var object = new PointLight();
        object.dispose();
        // ensure calls dispose() on shadow
    }

    @Test
    public function testCopy() {
        TODO('everything\'s gonna be alright');
    }

    // OTHERS
    @Test
    public function testStandardLightTests() {
        runStdLightTests(this, lights);
    }
}