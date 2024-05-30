package three.js.test.unit.src.math.interpolants;

import three.js.src.math.interpolants.CubicInterpolant;
import three.js.src.math.Interpolant;
import js.Lib;

class CubicInterpolantTests {

    static function main() {
        QUnit.module('Maths', () -> {
            QUnit.module('Interpolants', () -> {
                QUnit.module('CubicInterpolant', () -> {
                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.strictEqual(
                            Std.is(object, Interpolant), true,
                            'CubicInterpolant extends from Interpolant'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        // parameterPositions, sampleValues, sampleSize, resultBuffer
                        var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.ok(object, 'Can instantiate a CubicInterpolant.');
                    });

                    // PRIVATE - TEMPLATE METHODS
                    QUnit.todo('intervalChanged_', (assert) -> {
                        // intervalChanged_(i1, t0, t1)
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

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