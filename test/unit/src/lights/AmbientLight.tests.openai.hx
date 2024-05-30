package three.lights;

import haxe.unit.TestCase;

class AmbientLightTest extends TestCase {

    private var lights:Array<AmbientLight>;

    override public function setup() {
        var parameters = {
            color: 0xaaaaaa,
            intensity: 0.5
        };
        lights = [
            new AmbientLight(),
            new AmbientLight(parameters.color),
            new AmbientLight(parameters.color, parameters.intensity)
        ];
    }

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
        runStdLightTests(lights);
    }
}