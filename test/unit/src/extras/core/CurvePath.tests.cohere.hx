package;

import js.QUnit;
import js.CurvePath;
import js.Curve;

class CurvePathTest {
    static function main() {
        QUnit.module('Extras', function() {
            QUnit.module('Core', function() {
                QUnit.module('CurvePath', function() {
                    // INHERITANCE
                    QUnit.test('Extending', function(assert) {
                        var object = new CurvePath();
                        assert.strictEqual(Std.is(object, Curve), true, 'CurvePath extends from Curve');
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        var object = new CurvePath();
                        assert.ok(object, 'Can instantiate a CurvePath.');
                    });

                    // PROPERTIES
                    QUnit.test('type', function(assert) {
                        var object = new Curve();
                        assert.ok(object.type == 'Curve', 'Curve.type should be Curve');
                    });

                    QUnit.todo('curves', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('autoClose', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    // PUBLIC
                    QUnit.todo('add', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('closePath', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('getPoint', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('getLength', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('updateArcLengths', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('getCurveLengths', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('getSpacedPoints', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('getPoints', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('copy', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('toJSON', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('fromJSON', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}