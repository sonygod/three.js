import qunit.QUnit;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.KeyframeTrack;

class AnimationTest {
  static function main() {
    QUnit.module("Animation", function() {
      QUnit.module("Tracks", function() {
        QUnit.module("QuaternionKeyframeTrack", function() {
          var parameters = {
            name: ".rotation",
            times: [0],
            values: [0.5, 0.5, 0.5, 1],
            interpolation: QuaternionKeyframeTrack.DefaultInterpolation
          };

          // INHERITANCE
          QUnit.test("Extending", function(assert) {
            var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.strictEqual(object instanceof KeyframeTrack, true, "QuaternionKeyframeTrack extends from KeyframeTrack");
          });

          // INSTANCING
          QUnit.test("Instancing", function(assert) {
            // name, times, values
            var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.ok(object, "Can instantiate a QuaternionKeyframeTrack.");

            // name, times, values, interpolation
            var object_all = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
            assert.ok(object_all, "Can instantiate a QuaternionKeyframeTrack with name, times, values, interpolation.");
          });
        });
      });
    });
  }
}

class Main {
  static function main() {
    AnimationTest.main();
  }
}