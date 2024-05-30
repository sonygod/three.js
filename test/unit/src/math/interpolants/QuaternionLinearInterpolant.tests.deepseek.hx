package;

import js.Lib;
import js.QUnit;

import three.js.math.interpolants.QuaternionLinearInterpolant;
import three.js.math.Interpolant;

class QuaternionLinearInterpolantTest {

    static function main() {

        QUnit.module('Maths', () -> {

            QUnit.module('Interpolants', () -> {

                QUnit.module('QuaternionLinearInterpolant', () -> {

                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {

                        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.strictEqual(
                            Std.is(object, Interpolant), true,
                            'QuaternionLinearInterpolant extends from Interpolant'
                        );

                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {

                        // parameterPositions, sampleValues, sampleSize, resultBuffer
                        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.ok(object, 'Can instantiate a QuaternionLinearInterpolant.');

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