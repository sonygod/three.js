package;

import js.Lib;
import js.Browser.window;
import three.js.test.unit.src.animation.tracks.ColorKeyframeTrack;
import three.js.test.unit.src.animation.KeyframeTrack;

class Main {
    static function main() {
        var QUnit = Lib.require('qunit');

        QUnit.module('Animation', function() {
            QUnit.module('Tracks', function() {
                QUnit.module('ColorKeyframeTrack', function() {
                    var parameters = {
                        name: '.material.diffuse',
                        times: [0, 1],
                        values: [0, 0.5, 1.0],
                        interpolation: ColorKeyframeTrack.DefaultInterpolation
                    };

                    // INHERITANCE
                    QUnit.test('Extending', function(assert) {
                        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(
                            Std.is(object, KeyframeTrack), true,
                            'ColorKeyframeTrack extends from KeyframeTrack'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        // name, times, values
                        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object, 'Can instantiate a ColorKeyframeTrack.');

                        // name, times, values, interpolation
                        var object_all = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
                        assert.ok(object_all, 'Can instantiate a ColorKeyframeTrack with name, times, values, interpolation.');
                    });
                });
            });
        });
    }
}