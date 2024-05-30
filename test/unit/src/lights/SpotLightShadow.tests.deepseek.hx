package three.js.test.unit.src.lights;

import three.js.src.lights.SpotLightShadow;
import three.js.src.lights.LightShadow;
import three.js.src.lights.SpotLight;
import three.js.src.loaders.ObjectLoader;

class SpotLightShadowTests {

    static function main() {

        // INHERITANCE
        var object = new SpotLightShadow();
        unittest.assert(object instanceof LightShadow);

        // INSTANCING
        var object = new SpotLightShadow();
        unittest.assert(object != null);

        // PROPERTIES
        // TODO: focus

        // PUBLIC
        var object = new SpotLightShadow();
        unittest.assert(object.isSpotLightShadow);

        // TODO: updateMatrices

        // TODO: copy

        // OTHERS
        var a = new SpotLightShadow();
        var b = new SpotLightShadow();

        unittest.assert(a != b);

        var c = a.clone();
        unittest.assert(a == c);

        c.mapSize.set(256, 256);
        unittest.assert(a != c);

        b.copy(a);
        unittest.assert(a == b);

        b.mapSize.set(512, 512);
        unittest.assert(a != b);

        var light = new SpotLight();
        var shadow = new SpotLightShadow();

        shadow.bias = 10;
        shadow.radius = 5;
        shadow.mapSize.set(128, 128);
        light.shadow = shadow;

        var json = light.toJSON();
        var newLight = new ObjectLoader().parse(json);

        unittest.assert(newLight.shadow == light.shadow);

    }

}