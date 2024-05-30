package;

import js.Lib;
import js.QUnit;
import three.math.Interpolant;
import three.math.interpolants.LinearInterpolant;

class Main {
    static function main() {
        QUnit.module('Maths', () -> {
            QUnit.module('Interpolants', () -> {
                QUnit.module('LinearInterpolant', () -> {
                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.strictEqual(
                            Std.is(object, Interpolant), true,
                            'LinearInterpolant extends from Interpolant'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.ok(object != null, 'Can instantiate a LinearInterpolant.');
                    });

                    // PRIVATE - TEMPLATE METHODS
                    QUnit.todo('interpolate_', (assert) -> {
                        // interpolate_(i1, t0, t, t1)
                        // return equal to base class Interpolant.resultBuffer after call
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}