import js.QUnit;
import ArcCurve from '../../../../../src/extras/curves/ArcCurve.hx';
import EllipseCurve from '../../../../../src/extras/curves/EllipseCurve.hx';

class _Main {
    static function main() {
        QUnit.module('Extras', function() {
            QUnit.module('Curves', function() {
                QUnit.module('ArcCurve', function() {
                    // INHERITANCE
                    QUnit.test('Extending', function(assert) {
                        var object = new ArcCurve();
                        assert.strictEqual(object instanceof EllipseCurve, true, 'ArcCurve extends from EllipseCurve');
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        var object = new ArcCurve();
                        assert.ok(object, 'Can instantiate an ArcCurve.');
                    });

                    // PROPERTIES
                    QUnit.test('type', function(assert) {
                        var object = new ArcCurve();
                        assert.ok(object.type() == 'ArcCurve', 'ArcCurve.type should be ArcCurve');
                    });

                    // PUBLIC
                    QUnit.test('isArcCurve', function(assert) {
                        var object = new ArcCurve();
                        assert.ok(object.isArcCurve(), 'ArcCurve.isArcCurve should be true');
                    });
                });
            });
        });
    }
}