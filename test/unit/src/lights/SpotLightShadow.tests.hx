package three.test.unit.src.lights;

import haxe.unit.TestCase;

class SpotLightShadowTests {
    public function new() {}

    public function testExtending() {
        var object = new SpotLightShadow();
        assertEquals(true, Std.is(object, LightShadow), 'SpotLightShadow extends from LightShadow');
    }

    public function testInstancing() {
        var object = new SpotLightShadow();
        assertTrue(object != null, 'Can instantiate a SpotLightShadow.');
    }

    public function testFocus() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsSpotLightShadow() {
        var object = new SpotLightShadow();
        assertTrue(object.isSpotLightShadow, 'SpotLightShadow.isSpotLightShadow should be true');
    }

    public function testUpdateMatrices() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCopy() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCloneCopy() {
        var a = new SpotLightShadow();
        var b = new SpotLightShadow();

        assertNotDeepEqual(a, b, 'Newly instanced shadows are not equal');

        var c = a.clone();
        assertSmartEqual(a, c, 'Shadows are identical after clone()');

        c.mapSize.set(256, 256);
        assertNotDeepEqual(a, c, 'Shadows are different again after change');

        b.copy(a);
        assertSmartEqual(a, b, 'Shadows are identical after copy()');

        b.mapSize.set(512, 512);
        assertNotDeepEqual(a, b, 'Shadows are different again after change');
    }

    public function testToJSON() {
        var light = new SpotLight();
        var shadow = new SpotLightShadow();

        shadow.bias = 10;
        shadow.radius = 5;
        shadow.mapSize.set(128, 128);
        light.shadow = shadow;

        var json = light.toJSON();
        var newLight = new ObjectLoader().parse(json);

        assertSmartEqual(newLight.shadow, light.shadow, 'Reloaded shadow is equal to the original one');
    }
}