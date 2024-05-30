package;

import js.Lib;
import js.Browser.window;
import js.QUnit.QUnit;
import three.animation.tracks.BooleanKeyframeTrack;
import three.animation.KeyframeTrack;

class Main {
    static function main() {
        QUnit.module('Animation', () -> {
            QUnit.module('Tracks', () -> {
                QUnit.module('BooleanKeyframeTrack', () -> {
                    var parameters = {
                        name: '.visible',
                        times: [0, 1],
                        values: [true, false]
                    };

                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(
                            Std.is(object, KeyframeTrack), true,
                            'BooleanKeyframeTrack extends from KeyframeTrack'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object, 'Can instantiate a BooleanKeyframeTrack.');
                    });
                });
            });
        });
    }
}