package three.animation;

import haxe.unit.TestCase;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.KeyframeTrack;

class KeyframeTrackTest {
  public function new() {}

  public function testExtending() {
    var parameters = {
      name: '.material.opacity',
      times: [0, 1],
      values: [0, 0.5],
      interpolation: NumberKeyframeTrack.DefaultInterpolation
    };

    var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
    TestCase.assertEquals(object instanceof KeyframeTrack, true, 'NumberKeyframeTrack extends from KeyframeTrack');
  }

  public function testInstancing() {
    var parameters = {
      name: '.material.opacity',
      times: [0, 1],
      values: [0, 0.5],
      interpolation: NumberKeyframeTrack.DefaultInterpolation
    };

    var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
    TestCase.notNull(object, 'Can instantiate a NumberKeyframeTrack.');

    var object_all = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
    TestCase.notNull(object_all, 'Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.');
  }

  public function testValidate() {
    var validTrack = new NumberKeyframeTrack('.material.opacity', [0, 1], [0, 0.5]);
    var invalidTrack = new NumberKeyframeTrack('.material.opacity', [0, 1], [0, Math.NaN]);

    TestCase.isTrue(validTrack.validate());

    Console.setLevel(CONSOLE_LEVEL.OFF);
    TestCase.isFalse(invalidTrack.validate());
    Console.setLevel(CONSOLE_LEVEL.DEFAULT);
  }

  public function testOptimize() {
    var track = new NumberKeyframeTrack('.material.opacity', [0, 1, 2, 3, 4], [0, 0, 0, 0, 1]);

    TestCase.assertEquals(track.values.length, 5);

    track.optimize();

    TestCase.assertEquals(track.times, [0, 3, 4]);
    TestCase.assertEquals(track.values, [0, 0, 1]);
  }

  public static function main() {
    var test = new KeyframeTrackTest();
    test.testExtending();
    test.testInstancing();
    test.testValidate();
    test.testOptimize();
  }
}