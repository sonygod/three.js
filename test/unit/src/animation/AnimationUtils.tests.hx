package three.test.unit.src.animation;

import haxe.unit.TestRunner;
import haxe.unit.TestCase;

class AnimationUtilsTests {
  public function new() {}

  public function testAll() {
    var testRunner = new TestRunner();
    testRunner.add(new AnimationUtilsTest());
    testRunner.run();
  }
}

class AnimationUtilsTest extends TestCase {
  public function new() {
    super();
  }

  override public function setup() {}

  override public function tearDown() {}

  public function testConvertArray() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function testIsTypedArray() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function testGetKeyframeOrder() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function testSortedArray() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function testFlattenJSON() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function testSubclip() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function testMakeClipAdditive() {
    assertTrue(false, "everything's gonna be alright");
  }
}