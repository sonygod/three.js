import js.Browser.document;
import js.html.QUnit;
import threejs.animation.tracks.StringKeyframeTrack;
import threejs.animation.KeyframeTrack;

class StringKeyframeTrackTests {
    public function new() {
        QUnit.module("Animation", () -> {
            QUnit.module("Tracks", () -> {
                QUnit.module("StringKeyframeTrack", () -> {
                    var parameters = {
                        name: ".name",
                        times: [0, 1],
                        values: ["foo", "bar"]
                    };

                    // INHERITANCE
                    QUnit.test("Extending", (assert) -> {
                        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(Std.is(object, KeyframeTrack), true, "StringKeyframeTrack extends from KeyframeTrack");
                    });

                    // INSTANCING
                    QUnit.test("Instancing", (assert) -> {
                        // name, times, values
                        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.isNotNull(object, "Can instantiate a StringKeyframeTrack.");
                    });
                });
            });
        });
    }
}