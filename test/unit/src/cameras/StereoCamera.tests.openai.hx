import haxe.unit.TestCase;
import three.cameras.StereoCamera;

class StereoCameraTests {
  public function new() {
    TestCase.addTest(new TestStereoCamera());
  }
}

class TestStereoCamera extends TestCase {
  public function testInstancing() {
    var object = new StereoCamera();
    PHPUnit.assertNotNull(object, 'Can instantiate a StereoCamera.');
  }

  public function testType() {
    var object = new StereoCamera();
    assertEquals('StereoCamera', object.type, 'StereoCamera.type should be StereoCamera');
  }

  public function testAspect() {
    #if !todo
    PHPUnit.fail("Not implemented");
    #end
  }

  public function testEyeSep() {
    #if !todo
    PHPUnit.fail("Not implemented");
    #end
  }

  public function testCameraL() {
    #if !todo
    PHPUnit.fail("Not implemented");
    #end
  }

  public function testCameraR() {
    #if !todo
    PHPUnit.fail("Not implemented");
    #end
  }

  public function testUpdate() {
    #if !todo
    PHPUnit.fail("Not implemented");
    #end
  }
}