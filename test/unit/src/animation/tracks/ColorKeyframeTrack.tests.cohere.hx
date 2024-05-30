package;

import js.QUnit.QUnit;
import js.THREE.animation.ColorKeyframeTrack;
import js.THREE.animation.KeyframeTrack;

class TestColorKeyframeTrack {
    static var parameters = {
        name: '.material.diffuse',
        times: [0, 1],
        values: [0, 0.5, 1.0],
        interpolation: ColorKeyframeTrack.DefaultInterpolation
    };

    public static function extending() {
        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        QUnit.strictEqual(object instanceof KeyframeTrack, true, 'ColorKeyframeTrack extends from KeyframeTrack');
    }

    public static function instancing() {
        // name, times, values
        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        QUnit.ok(object, 'Can instantiate a ColorKeyframeTrack.');

        // name, times, values, interpolation
        var object_all = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        QUnit.ok(object_all, 'Can instantiate a ColorKeyframeTrack with name, times, values, interpolation.');
    }
}

QUnit.module('Animation', function () {
    QUnit.module('Tracks', function () {
        QUnit.module('ColorKeyframeTrack', function () {
            QUnit.test('Extending', TestColorKeyframeTrack.extending);
            QUnit.test('Instancing', TestColorKeyframeTrack.instancing);
        });
    });
});