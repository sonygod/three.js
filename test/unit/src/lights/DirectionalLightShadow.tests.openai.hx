package three.js.test.unit.src.lights;

import three.js.lights.DirectionalLightShadow;
import three.js.lights.LightShadow;
import three.js.loaders.ObjectLoader;
import three.js.lights.DirectionalLight;

class DirectionalLightShadowTests {
    public function new() {}

    public function testExtending(assert: Assert): Void {
        var object: DirectionalLightShadow = new DirectionalLightShadow();
        assert.isTrue(Std.is(object, LightShadow), 'DirectionalLightShadow extends from LightShadow');
    }

    public function testInstancing(assert: Assert): Void {
        var object: DirectionalLightShadow = new DirectionalLightShadow();
        assert.ok(object, 'Can instantiate a DirectionalLightShadow.');
    }

    public function testIsDirectionalLightShadow(assert: Assert): Void {
        var object: DirectionalLightShadow = new DirectionalLightShadow();
        assert.ok(object.isDirectionalLightShadow, 'DirectionalLightShadow.isDirectionalLightShadow should be true');
    }

    public function testCloneCopy(assert: Assert): Void {
        var a: DirectionalLightShadow = new DirectionalLightShadow();
        var b: DirectionalLightShadow = new DirectionalLightShadow();

        assert.notDeepEqual(a, b, 'Newly instanced shadows are not equal');

        var c: DirectionalLightShadow = a.clone();
        assert.smartEqual(a, c, 'Shadows are identical after clone()');

        c.mapSize.set(1024, 1024);
        assert.notDeepEqual(a, c, 'Shadows are different again after change');

        b.copy(a);
        assert.smartEqual(a, b, 'Shadows are identical after copy()');

        b.mapSize.set(512, 512);
        assert.notDeepEqual(a, b, 'Shadows are different again after change');
    }

    public function testToJSON(assert: Assert): Void {
        var light: DirectionalLight = new DirectionalLight();
        var shadow: DirectionalLightShadow = new DirectionalLightShadow();

        shadow.bias = 10;
        shadow.radius = 5;
        shadow.mapSize.set(1024, 1024);
        light.shadow = shadow;

        var json: Dynamic = light.toJSON();
        var newLight: Dynamic = new ObjectLoader().parse(json);

        assert.smartEqual(newLight.shadow, light.shadow, 'Reloaded shadow is identical to the original one');
    }
}