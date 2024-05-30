import js.Browser.*;
import js.three.animation.tracks.StringKeyframeTrack;
import js.three.animation.KeyframeTrack;

class StringKeyframeTrackTests {
    public static function new() {
        QUnit.module("Animation", () -> {
            QUnit.module("Tracks", () -> {
                QUnit.module("StringKeyframeTrack", () -> {
                    var parameters = {
                        name: ".name",
                        times: [0, 1],
                        values: ["foo", "bar"],
                    };

                    // INHERITANCE
                    QUnit.test("Extending", (assert) -> {
                        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(Std.is(object, KeyframeTrack), "StringKeyframeTrack extends from KeyframeTrack");
                    });

                    // INSTANCING
                    QUnit.test("Instancing", (assert) -> {
                        // name, times, values
                        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object != null, "Can instantiate a StringKeyframeTrack.");
                    });
                });
            });
        });
    }
}