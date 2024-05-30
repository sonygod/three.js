package;

import three.js.test.unit.src.animation.tracks.NumberKeyframeTrack;
import three.js.test.unit.src.animation.KeyframeTrack;
import js.QUnit;

class Main {
    static function main() {
        QUnit.module('Animation', () -> {
            QUnit.module('Tracks', () -> {
                QUnit.module('NumberKeyframeTrack', () -> {
                    var parameters = {
                        name: '.material.opacity',
                        times: [0, 1],
                        values: [0, 0.5],
                        interpolation: NumberKeyframeTrack.DefaultInterpolation
                    };

                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(
                            Std.is(object, KeyframeTrack), true,
                            'NumberKeyframeTrack extends from KeyframeTrack'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        // name, times, values
                        var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object, 'Can instantiate a NumberKeyframeTrack.');

                        // name, times, values, interpolation
                        var object_all = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
                        assert.ok(object_all, 'Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.');
                    });
                });
            });
        });
    }
}