package three.helpers;

import haxe.unit.TestCase;
import three.core.Object3D;
import three.lights.SpotLight;
import three.helpers.SpotLightHelper;

class SpotLightHelperTest {
    public function new() {}

    public function testExtending() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        assertEquals(object instanceof Object3D, true, 'SpotLightHelper extends from Object3D');
    }

    public function testInstancing() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        assertNotNull(object, 'Can instantiate a SpotLightHelper.');
    }

    public function testType() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        assertEquals(object.type, 'SpotLightHelper', 'SpotLightHelper.type should be SpotLightHelper');
    }

    public function testDispose() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        object.dispose();
    }

    public function todoLight() {
        fail("everything's gonna be alright");
    }

    public function todoMatrix() {
        fail("everything's gonna be alright");
    }

    public function todoMatrixAutoUpdate() {
        fail("everything's gonna be alright");
    }

    public function todoColor() {
        fail("everything's gonna be alright");
    }

    public function todoCone() {
        fail("everything's gonna be alright");
    }

    public function todoUpdate() {
        fail("everything's gonna be alright");
    }
}