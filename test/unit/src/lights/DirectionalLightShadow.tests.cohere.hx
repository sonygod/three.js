import js.QUnit;

import js.THREE.DirectionalLightShadow;
import js.THREE.LightShadow;
import js.THREE.ObjectLoader;
import js.THREE.DirectionalLight;

class DirectionalLightShadowTest {
    static function extending() {
        var object = new DirectionalLightShadow();
        var assert = QUnit.assert;
        assert.strictEqual(Std.is(object, LightShadow), true, 'DirectionalLightShadow extends from LightShadow');
    }

    static function instancing() {
        var object = new DirectionalLightShadow();
        var assert = QUnit.assert;
        assert.ok(object, 'Can instantiate a DirectionalLightShadow.');
    }

    static function isDirectionalLightShadow() {
        var object = new DirectionalLightShadow();
        var assert = QUnit.assert;
        assert.ok(object.isDirectionalLightShadow, 'DirectionalLightShadow.isDirectionalLightShadow should be true');
    }

    static function cloneCopy() {
        var a = new DirectionalLightShadow();
        var b = new DirectionalLightShadow();
        var assert = QUnit.assert;
        assert.notDeepEqual(a, b, 'Newly instanced shadows are not equal');

        var c = a.clone();
        assert.smartEqual(a, c, 'Shadows are identical after clone()');

        c.mapSize.set(1024, 1024);
        assert.notDeepEqual(a, c, 'Shadows are different again after change');

        b.copy(a);
        assert.smartEqual(a, b, 'Shadows are identical after copy()');

        b.mapSize.set(512, 512);
        assert.notDeepEqual(a, b, 'Shadows are different again after change');
    }

    static function toJSON() {
        var light = new DirectionalLight();
        var shadow = new DirectionalLightShadow();
        shadow.bias = 10;
        shadow.radius = 5;
        shadow.mapSize.set(1024, 1024);
        light.shadow = shadow;

        var json = light.toJSON();
        var newLight = new ObjectLoader().parse(json);

        var assert = QUnit.assert;
        assert.smartEqual(newLight.shadow, light.shadow, 'Reloaded shadow is identical to the original one');
    }
}

QUnit.module('Lights', {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.module('DirectionalLightShadow', {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.test('Extending', DirectionalLightShadowTest.extending);
QUnit.test('Instancing', DirectionalLightShadowTest.instancing);
QUnit.test('isDirectionalLightShadow', DirectionalLightShadowTest.isDirectionalLightShadow);
QUnit.test('clone/copy', DirectionalLightShadowTest.cloneCopy);
QUnit.test('toJSON', DirectionalLightShadowTest.toJSON);