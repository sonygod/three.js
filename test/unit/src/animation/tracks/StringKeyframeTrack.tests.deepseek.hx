package;

import js.Lib;
import js.Browser.window;
import three.js.test.unit.src.animation.tracks.StringKeyframeTrack;
import three.js.test.unit.src.animation.KeyframeTrack;

class Main {
    static function main() {
        var QUnit = Lib.require('QUnit');

        QUnit.module('Animation', function() {
            QUnit.module('Tracks', function() {
                QUnit.module('StringKeyframeTrack', function() {
                    var parameters = {
                        name: '.name',
                        times: [0, 1],
                        values: ['foo', 'bar']
                    };

                    // INHERITANCE
                    QUnit.test('Extending', function(assert) {
                        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(
                            Std.is(object, KeyframeTrack), true,
                            'StringKeyframeTrack extends from KeyframeTrack'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object, 'Can instantiate a StringKeyframeTrack.');
                    });
                });
            });
        });
    }
}