import qunit.QUnit;
import three.animation.tracks.BooleanKeyframeTrack;
import three.animation.KeyframeTrack;

class BooleanKeyframeTrackTests {
    public static function main() {
        QUnit.module("Animation", () -> {
            QUnit.module("Tracks", () -> {
                QUnit.module("BooleanKeyframeTrack", () -> {
                    var parameters = {
                        name: ".visible",
                        times: [0, 1],
                        values: [true, false]
                    };

                    // INHERITANCE
                    QUnit.test("Extending", (assert) -> {
                        var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.isTrue(Std.is(object, KeyframeTrack), "BooleanKeyframeTrack extends from KeyframeTrack");
                    });

                    // INSTANCING
                    QUnit.test("Instancing", (assert) -> {
                        // name, times, values
                        var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object != null, "Can instantiate a BooleanKeyframeTrack.");
                    });
                });
            });
        });
    }
}