import js.QUnit;
import js.VectorKeyframeTrack;
import js.KeyframeTrack;

class TestAnimation {
    public static function run():Void {
        QUnit.module( 'Animation', function() {
            QUnit.module( 'Tracks', function() {
                QUnit.module( 'VectorKeyframeTrack', function() {
                    var parameters = {
                        'name': '.force',
                        'times': [ 0 ],
                        'values': [ 0.5, 0.5, 0.5 ],
                        'interpolation': VectorKeyframeTrack.DefaultInterpolation
                    };

                    // INHERITANCE
                    QUnit.test( 'Extending', function( assert ) {
                        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        assert.strictEqual(object instanceof KeyframeTrack, true, 'VectorKeyframeTrack extends from KeyframeTrack');
                    });

                    // INSTANCING
                    QUnit.test( 'Instancing', function( assert ) {
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

TestAnimation.run();