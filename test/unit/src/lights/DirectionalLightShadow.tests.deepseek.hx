package three.js.test.unit.src.lights;

import three.js.src.lights.DirectionalLightShadow;
import three.js.src.lights.LightShadow;
import three.js.src.loaders.ObjectLoader;
import three.js.src.lights.DirectionalLight;

class DirectionalLightShadowTests {

    static function main() {

        // INHERITANCE
        var object = new DirectionalLightShadow();
        unittest.assert(object instanceof LightShadow);

        // INSTANCING
        var object = new DirectionalLightShadow();
        unittest.assert(object != null);

        // PUBLIC
        var object = new DirectionalLightShadow();
        unittest.assert(object.isDirectionalLightShadow);

        // OTHERS
        var a = new DirectionalLightShadow();
        var b = new DirectionalLightShadow();

        unittest.assert(!unittest.compare(a, b));

        var c = a.clone();
        unittest.assert(unittest.compare(a, c));

        c.mapSize.set(1024, 1024);
        unittest.assert(!unittest.compare(a, c));

        b.copy(a);
        unittest.assert(unittest.compare(a, b));

        b.mapSize.set(512, 512);
        unittest.assert(!unittest.compare(a, b));

        var light = new DirectionalLight();
        var shadow = new DirectionalLightShadow();

        shadow.bias = 10;
        shadow.radius = 5;
        shadow.mapSize.set(1024, 1024);
        light.shadow = shadow;

        var json = light.toJSON();
        var newLight = new ObjectLoader().parse(json);

        unittest.assert(unittest.compare(newLight.shadow, light.shadow));

    }

}