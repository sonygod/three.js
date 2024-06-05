import qunit.QUnit;
import three.animation.tracks.BooleanKeyframeTrack;
import three.animation.KeyframeTrack;

class AnimationTest {
  static function main() {
    QUnit.module("Animation", function() {
      QUnit.module("Tracks", function() {
        QUnit.module("BooleanKeyframeTrack", function() {
          var parameters = {
            name: ".visible",
            times: [0, 1],
            values: [true, false]
          };

          // INHERITANCE
          QUnit.test("Extending", function(assert) {
            var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.strictEqual(object instanceof KeyframeTrack, true, "BooleanKeyframeTrack extends from KeyframeTrack");
          });

          // INSTANCING
          QUnit.test("Instancing", function(assert) {
            // name, times, values
            var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.ok(object, "Can instantiate a BooleanKeyframeTrack.");
          });
        });
      });
    });
  }
}

AnimationTest.main();