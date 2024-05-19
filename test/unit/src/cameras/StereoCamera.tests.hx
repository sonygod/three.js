package three.test.unit.src.cameras;

import haxe.unit.TestCase;
import three.cameras.StereoCamera;

class StereoCameraTest {
    public function new() {}

    public function testInstancing() {
        var object = new StereoCamera();
        assertTrue(object != null, 'Can instantiate a StereoCamera.');
    }

    public function testType() {
        var object = new StereoCamera();
        assertEquals(object.type, 'StereoCamera', 'StereoCamera.type should be StereoCamera');
    }

    public function testAspect() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testEyeSep() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCameraL() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCameraR() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testUpdate() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main() {
        var testCase = new StereoCameraTest();
        testCase.testInstancing();
        testCase.testType();
        testCase.testAspect();
        testCase.testEyeSep();
        testCase.testCameraL();
        testCase.testCameraR();
        testCase.testUpdate();
    }
}