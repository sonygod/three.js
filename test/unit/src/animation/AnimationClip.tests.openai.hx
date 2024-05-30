import haxe.unit.TestCase;
import three.animation.AnimationClip;

class AnimationClipTest {
  public function new() {}

  public function testInstancing() {
    var clip = new AnimationClip("clip1", 1000, [{}]);
    assertTrue(clip != null, "AnimationClip can be instanciated");
  }

  public function testName() {
    var clip = new AnimationClip("clip1", 1000, [{}]);
    assertEquals(clip.name, "clip1", "AnimationClip can be named");
  }

  // TODO: implement other test cases...

  public function new() {
    TestCase.asyncTest("Animation", function(async:Async) {
      TestCase.module("AnimationClip", function() {
        TestCase.test("Instancing", testInstancing);
        TestCase.test("name", testName);
        // Add other test cases here...
      });
    });
  }
}