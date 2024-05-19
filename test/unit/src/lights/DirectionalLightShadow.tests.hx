package three.test.unit.src.lights;

import three.lights.DirectionalLightShadow;
import three.lights.LightShadow;
import three.loaders.ObjectLoader;
import three.lights.DirectionalLight;

class DirectionalLightShadowTests {
    public function new() {}

    public static function main():Void {
        Utest.module("Lights", () -> {
            Utest.module("DirectionalLightShadow", () -> {
                // INHERITANCE
                Utest.test("Extending", (assert:Utest.Assert) -> {
                    var object = new DirectionalLightShadow();
                    assert.isTrue(object instanceof LightShadow, "DirectionalLightShadow extends from LightShadow");
                });

                // INSTANCING
                Utest.test("Instancing", (assert:Utest.Assert) -> {
                    var object = new DirectionalLightShadow();
                    assert.notNull(object, "Can instantiate a DirectionalLightShadow.");
                });

                // PUBLIC
                Utest.test("isDirectionalLightShadow", (assert:Utest.Assert) -> {
                    var object = new DirectionalLightShadow();
                    assert.isTrue(object.isDirectionalLightShadow, "DirectionalLightShadow.isDirectionalLightShadow should be true");
                });

                // OTHERS
                Utest.test("clone/copy", (assert:Utest.Assert) -> {
                    var a = new DirectionalLightShadow();
                    var b = new DirectionalLightShadow();

                    assert.notEqual(a, b, "Newly instanced shadows are not equal");

                    var c = a.clone();
                    assert.deepEqual(a, c, "Shadows are identical after clone()");

                    c.mapSize.set(1024, 1024);
                    assert.notEqual(a, c, "Shadows are different again after change");

                    b.copy(a);
                    assert.deepEqual(a, b, "Shadows are identical after copy()");

                    b.mapSize.set(512, 512);
                    assert.notEqual(a, b, "Shadows are different again after change");
                });

                Utest.test("toJSON", (assert:Utest.Assert) -> {
                    var light = new DirectionalLight();
                    var shadow = new DirectionalLightShadow();

                    shadow.bias = 10;
                    shadow.radius = 5;
                    shadow.mapSize.set(1024, 1024);
                    light.shadow = shadow;

                    var json = light.toJSON();
                    var newLight = new ObjectLoader().parse(json);

                    assert.deepEqual(newLight.shadow, light.shadow, "Reloaded shadow is identical to the original one");
                });
            });
        });
    }
}