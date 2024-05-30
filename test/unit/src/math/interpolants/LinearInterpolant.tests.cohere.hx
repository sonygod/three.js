import js.QUnit;
import js.math.interpolants.LinearInterpolant;
import js.math.Interpolant;

class TestMaths {
    static function testInterpolants() {
        QUnit.module( 'Maths > Interpolants', function() {
            QUnit.module( 'LinearInterpolant', function() {
                // INHERITANCE
                QUnit.test( 'Extending', function( assert ) {
                    var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                    assert.strictEqual(object instanceof Interpolant, true, 'LinearInterpolant extends from Interpolant');
                });

                // INSTANCING
                QUnit.test( 'Instancing', function( assert ) {
                    var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                    assert.ok(object, 'Can instantiate a LinearInterpolant.');
                });

                // PRIVATE - TEMPLATE METHODS
                QUnit.todo( 'interpolate_', function( assert ) {
                    // interpolate_( i1, t0, t, t1 )
                    // return equal to base class Interpolant.resultBuffer after call
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}

TestMaths.testInterpolants();