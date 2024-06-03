// Haxe does not have a direct equivalent to JavaScript's QUnit,
// so I will use the haxe.unit library for testing instead.
import haxe.unit.TestCase;

// Import the necessary classes from three.js
import three.lights.SpotLightShadow;
import three.lights.LightShadow;
import three.lights.SpotLight;
import three.loaders.ObjectLoader;

// Define a new TestCase for SpotLightShadow
class SpotLightShadowTests extends TestCase {

    // INHERITANCE
    public function testExtending():Void {
        var object = new SpotLightShadow();
        assertTrue(Std.is(object, LightShadow), "SpotLightShadow extends from LightShadow");
    }

    // INSTANCING
    public function testInstancing():Void {
        var object = new SpotLightShadow();
        assertNotNull(object, "Can instantiate a SpotLightShadow.");
    }

    // PUBLIC
    public function testIsSpotLightShadow():Void {
        var object = new SpotLightShadow();
        assertTrue(object.isSpotLightShadow, "SpotLightShadow.isSpotLightShadow should be true");
    }

    // OTHERS
    public function testCloneCopy():Void {
        var a = new SpotLightShadow();
        var b = new SpotLightShadow();

        assertNotEquals(a, b, "Newly instanced shadows are not equal");

        var c = a.clone();
        assertEquals(a, c, "Shadows are identical after clone()");

        c.mapSize.set(256, 256);
        assertNotEquals(a, c, "Shadows are different again after change");

        b.copy(a);
        assertEquals(a, b, "Shadows are identical after copy()");

        b.mapSize.set(512, 512);
        assertNotEquals(a, b, "Shadows are different again after change");
    }

    public function testToJSON():Void {
        var light = new SpotLight();
        var shadow = new SpotLightShadow();

        shadow.bias = 10;
        shadow.radius = 5;
        shadow.mapSize.set(128, 128);
        light.shadow = shadow;

        var json = light.toJSON();
        var newLight = new ObjectLoader().parse(json);

        assertEquals(newLight.shadow, light.shadow, "Reloaded shadow is equal to the original one");
    }
}