package;

import js.Lib;
import js.Browser.window;
import js.QUnit.QUnit;
import three.js.animation.tracks.VectorKeyframeTrack;
import three.js.animation.KeyframeTrack;

class Main {
    static function main() {
        QUnit.module('Animation', () -> {
            QUnit.module('Tracks', () -> {
                QUnit.module('VectorKeyframeTrack', () -> {
                    var parameters = {
                        name: '.force',
                        times: [0],
                        values: [0.5, 0.5, 0.5],
                        interpolation: VectorKeyframeTrack.DefaultInterpolation
                    };

                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(
                            Std.instanceof(object, KeyframeTrack), true,
                            'VectorKeyframeTrack extends from KeyframeTrack'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        // name, times, values
                        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object, 'Can instantiate a VectorKeyframeTrack.');

                        // name, times, values, interpolation
                        var object_all = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
                        assert.ok(object_all, 'Can instantiate a VectorKeyframeTrack with name, times, values, interpolation.');
                    });
                });
            });
        });
    }
}