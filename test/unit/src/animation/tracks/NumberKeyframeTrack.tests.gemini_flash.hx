import qunit.QUnit;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.KeyframeTrack;

class AnimationTest {
  static function main() {
    QUnit.module("Animation", function() {
      QUnit.module("Tracks", function() {
        QUnit.module("NumberKeyframeTrack", function() {
          var parameters = {
            name: ".material.opacity",
            times: [0, 1],
            values: [0, 0.5],
            interpolation: NumberKeyframeTrack.DefaultInterpolation
          };

          // INHERITANCE
          QUnit.test("Extending", function(assert) {
            var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.strictEqual(object instanceof KeyframeTrack, true, "NumberKeyframeTrack extends from KeyframeTrack");
          });

          // INSTANCING
          QUnit.test("Instancing", function(assert) {
            // name, times, values
            var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.ok(object, "Can instantiate a NumberKeyframeTrack.");

            // name, times, values, interpolation
            var object_all = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
            assert.ok(object_all, "Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.");
          });
        });
      });
    });
  }
}

AnimationTest.main();