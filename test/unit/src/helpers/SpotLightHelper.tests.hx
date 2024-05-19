package three.helpers;

import haxe.unit.TestCase;
import three.core.Object3D;
import three.lights.SpotLight;
import three.helpers.SpotLightHelper;

class SpotLightHelperTest {
    public function new() {}

    public function testExtending() {
        var parameters:Dynamic = {
            color: 0xaaaaaa,
            intensity: 0.5,
            distance: 100,
            angle: 0.8,
            penumbra: 8,
            decay: 2
        };

        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        TestCase.assertEquals(object instanceof Object3D, true, 'SpotLightHelper extends from Object3D');
    }

    public function testInstancing() {
        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        TestCase.notNull(object, 'Can instantiate a SpotLightHelper.');
    }

    public function testType() {
        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        TestCase.assertEquals(object.type, 'SpotLightHelper', 'SpotLightHelper.type should be SpotLightHelper');
    }

    public function testTodoLight() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testTodoMatrix() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testTodoMatrixAutoUpdate() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testTodoColor() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testTodoCone() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testDispose() {
        var light = new SpotLight(parameters.color);
        var object = new SpotLightHelper(light, parameters.color);
        object.dispose();
    }

    public function testTodoUpdate() {
        TestCase.fail('everything\'s gonna be alright');
    }

    public static function main() {
        var testCase = new SpotLightHelperTest();
        testCase.testExtending();
        testCase.testInstancing();
        testCase.testType();
        testCase.testTodoLight();
        testCase.testTodoMatrix();
        testCase.testTodoMatrixAutoUpdate();
        testCase.testTodoColor();
        testCase.testTodoCone();
        testCase.testDispose();
        testCase.testTodoUpdate();
    }
}