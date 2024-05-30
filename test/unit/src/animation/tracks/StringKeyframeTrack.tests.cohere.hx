import js.Browser.QUnit;
import js.Browser.KeyframeTrack;
import js.Browser.StringKeyframeTrack;

class _Test {
    static function main() {
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
                        assert.strictEqual(object instanceof KeyframeTrack, true, 'StringKeyframeTrack extends from KeyframeTrack');
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        // name, times, values
                        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.ok(object, 'Can instantiate a StringKeyframeTrack.');
                    });
                });
            });
        });
    }
}