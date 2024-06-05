import qunit.QUnit;
import three.animation.AnimationClip;
import three.animation.AnimationMixer;
import three.animation.tracks.VectorKeyframeTrack;
import three.core.EventDispatcher;
import three.core.Object3D;
import three.math.Vector3;

class MathConstants {
  public static var zero3:Vector3 = new Vector3(0, 0, 0);
  public static var one3:Vector3 = new Vector3(1, 1, 1);
  public static var two3:Vector3 = new Vector3(2, 2, 2);
}

function getClips(pos1:Vector3, pos2:Vector3, scale1:Vector3, scale2:Vector3, dur:Float):Array<AnimationClip> {
  var clips:Array<AnimationClip> = [];

  var track = new VectorKeyframeTrack(".scale", [0, dur], [scale1.x, scale1.y, scale1.z, scale2.x, scale2.y, scale2.z]);
  clips.push(new AnimationClip("scale", dur, [track]));

  track = new VectorKeyframeTrack(".position", [0, dur], [pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z]);
  clips.push(new AnimationClip("position", dur, [track]));

  return clips;
}

class AnimationMixerTest extends QUnit.Test {
  public function new() {
    super();
  }

  override function testInheritance(assert:QUnit.Assert) {
    var object = new AnimationMixer();
    assert.ok(Std.is(object, EventDispatcher), "AnimationMixer extends from EventDispatcher");
  }

  override function testInstancing(assert:QUnit.Assert) {
    var object = new AnimationMixer();
    assert.ok(object != null, "Can instantiate a AnimationMixer.");
  }

  override function testStopAllAction(assert:QUnit.Assert) {
    var obj = new Object3D();
    var animMixer = new AnimationMixer(obj);
    var clips = getClips(MathConstants.zero3, MathConstants.one3, MathConstants.two3, MathConstants.one3, 1);
    var actionA = animMixer.clipAction(clips[0]);
    var actionB = animMixer.clipAction(clips[1]);

    actionA.play();
    actionB.play();
    animMixer.update(0.1);
    animMixer.stopAllAction();

    assert.ok(!actionA.isRunning() && !actionB.isRunning(), "All actions stopped");
    assert.ok(obj.position.x == 0 && obj.position.y == 0 && obj.position.z == 0, "Position reset as expected");
    assert.ok(obj.scale.x == 1 && obj.scale.y == 1 && obj.scale.z == 1, "Scale reset as expected");
  }

  override function testGetRoot(assert:QUnit.Assert) {
    var obj = new Object3D();
    var animMixer = new AnimationMixer(obj);
    assert.strictEqual(obj, animMixer.getRoot(), "Get original root object");
  }
}

QUnit.module("Animation", function() {
  QUnit.module("AnimationMixer", function() {
    new AnimationMixerTest().run(QUnit);
  });
});