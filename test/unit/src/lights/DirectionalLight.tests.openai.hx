package three.lights;

import haxe.unit.TestCase;

class DirectionalLightTest {

    public function new() {}

    public function testInheritance() {
        var light:DirectionalLight = new DirectionalLight();
        assertTrue(Std.is(light, Light), "DirectionalLight extends from Light");
    }

    public function testInstancing() {
        var light:DirectionalLight = new DirectionalLight();
        assertNotNull(light, "Can instantiate a DirectionalLight.");
    }

    public function testType() {
        var light:DirectionalLight = new DirectionalLight();
        assertEquals(light.type, "DirectionalLight", "DirectionalLight.type should be DirectionalLight");
    }

    // these tests are todo, so I'll leave them as empty functions for now
    public function testPosition() {}
    public function testTarget() {}
    public function testShadow() {}

    public function testIsDirectionalLight() {
        var light:DirectionalLight = new DirectionalLight();
        assertTrue(light.isDirectionalLight, "DirectionalLight.isDirectionalLight should be true");
    }

    public function testDispose() {
        var light:DirectionalLight = new DirectionalLight();
        light.dispose();
        // ensure calls dispose() on shadow
        // NOTE: this test is not implemented
    }

    public function testCopy() {}
    // this test is todo, so I'll leave it as an empty function for now

    public function testStandardLightTests() {
        var lights:Array<DirectionalLight> = [
            new DirectionalLight(),
            new DirectionalLight(0xaaaaaa),
            new DirectionalLight(0xaaaaaa, 0.8)
        ];
        // call the runStdLightTests function
        // NOTE: this function is not implemented in this example
    }
}