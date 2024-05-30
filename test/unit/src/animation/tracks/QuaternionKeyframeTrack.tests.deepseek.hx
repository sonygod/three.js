package;

import js.Lib;
import js.QUnit;

import three.js.animation.tracks.QuaternionKeyframeTrack;
import three.js.animation.KeyframeTrack;

class Main {
    static function main() {
        QUnit.module('Animation', () -> {
            QUnit.module('Tracks', () -> {
                QUnit.module('QuaternionKeyframeTrack', () -> {
                    var parameters = {
                        name: '.rotation',
                        times: [0],
                        values: [0.5, 0.5, 0.5, 1],
                        interpolation: QuaternionKeyframeTrack.DefaultInterpolation
                    };

                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(
                            Std.is(object, KeyframeTrack), true,
                            'QuaternionKeyframeTrack extends from KeyframeTrack'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        // name, times, values
                        var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object, 'Can instantiate a QuaternionKeyframeTrack.');

                        // name, times, values, interpolation
                        var object_all = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
                        assert.ok(object_all, 'Can instantiate a QuaternionKeyframeTrack with name, times, values, interpolation.');
                    });
                });
            });
        });
    }
}