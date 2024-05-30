package three.js.test.unit.src.helpers;

import three.js.src.helpers.SpotLightHelper;
import three.js.src.core.Object3D;
import three.js.src.lights.SpotLight;

class SpotLightHelperTests {

    static function main() {
        var parameters = {
            color: 0xaaaaaa,
            intensity: 0.5,
            distance: 100,
            angle: 0.8,
            penumbra: 8,
            decay: 2
        };

        // INHERITANCE
        testExtending(parameters);

        // INSTANCING
        testInstancing(parameters);

        // PROPERTIES
        testType(parameters);

        // PUBLIC
        testDispose(parameters);
    }

    static function testExtending(parameters:Dynamic) {
        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        unittest.assert(object instanceof Object3D);
    }

    static function testInstancing(parameters:Dynamic) {
        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        unittest.assert(object != null);
    }

    static function testType(parameters:Dynamic) {
        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        unittest.assert(object.type == "SpotLightHelper");
    }

    static function testDispose(parameters:Dynamic) {
        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        object.dispose();
    }
}