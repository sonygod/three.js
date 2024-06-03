import js.Browser.document;
import js.QUnit;
import three.animation.KeyframeTrack;
import three.animation.tracks.VectorKeyframeTrack;

class VectorKeyframeTrackTests {
    function new() {
        QUnit.module("Animation", () -> {
            QUnit.module("Tracks", () -> {
                QUnit.module("VectorKeyframeTrack", () -> {
                    var parameters = {
                        name: ".force",
                        times: [0],
                        values: [0.5, 0.5, 0.5],
                        interpolation: VectorKeyframeTrack.DefaultInterpolation
                    };

                    QUnit.test("Extending", (assert) -> {
                        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(Std.is(object, KeyframeTrack), true, "VectorKeyframeTrack extends from KeyframeTrack");
                    });

                    QUnit.test("Instancing", (assert) -> {
                        // name, times, values
                        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.notEqual(object, null, "Can instantiate a VectorKeyframeTrack.");

                        // name, times, values, interpolation
                        var object_all = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
                        assert.notEqual(object_all, null, "Can instantiate a VectorKeyframeTrack with name, times, values, interpolation.");
                    });
                });
            });
        });
    }
}