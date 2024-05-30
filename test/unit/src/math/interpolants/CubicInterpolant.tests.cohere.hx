import js.QUnit;
import js.math.interpolants.CubicInterpolant;
import js.math.Interpolant;

class TestCubicInterpolant {
    static function main() {
        QUnit.module('Maths', function() {
            QUnit.module('Interpolants', function() {
                QUnit.module('CubicInterpolant', function() {
                    // INHERITANCE
                    QUnit.test('Extending', function(assert) {
                        var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.strictEqual(object instanceof Interpolant, true, 'CubicInterpolant extends from Interpolant');
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        // parameterPositions, sampleValues, sampleSize, resultBuffer
                        var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.ok(object, 'Can instantiate a CubicInterpolant.');
                    });

                    // PRIVATE - TEMPLATE METHODS
                    QUnit.todo('intervalChanged_', function(assert) {
                        // intervalChanged_(i1, t0, t1)
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('interpolate_', function(assert) {
                        // interpolate_(i1, t0, t, t1)
                        // return equal to base class Interpolant.resultBuffer after call
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}

TestCubicInterpolant.main();