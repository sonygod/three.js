package;

import js.Lib;
import js.QUnit;

import three.js.math.interpolants.DiscreteInterpolant;
import three.js.math.Interpolant;

class Main {
    static function main() {
        QUnit.module('Maths', () -> {
            QUnit.module('Interpolants', () -> {
                QUnit.module('DiscreteInterpolant', () -> {
                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.strictEqual(
                            Std.is(object, Interpolant), true,
                            'DiscreteInterpolant extends from Interpolant'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        // parameterPositions, sampleValues, sampleSize, resultBuffer
                        var object = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.ok(object != null, 'Can instantiate a DiscreteInterpolant.');
                    });

                    // PRIVATE - TEMPLATE METHODS
                    QUnit.todo('interpolate_', (assert) -> {
                        // interpolate_(i1 /*, t0, t, t1 */)
                        // return equal to base class Interpolant.resultBuffer after call
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}