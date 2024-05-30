package;

import three.extras.curves.ArcCurve;
import three.extras.curves.EllipseCurve;
import js.Lib.QUnit;

class Main {
    static function main() {
        QUnit.module('Extras', () -> {
            QUnit.module('Curves', () -> {
                QUnit.module('ArcCurve', () -> {
                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new ArcCurve();
                        assert.strictEqual(
                            Std.is(object, EllipseCurve), true,
                            'ArcCurve extends from EllipseCurve'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        var object = new ArcCurve();
                        assert.ok(object, 'Can instantiate an ArcCurve.');
                    });

                    // PROPERTIES
                    QUnit.test('type', (assert) -> {
                        var object = new ArcCurve();
                        assert.ok(
                            object.type == 'ArcCurve',
                            'ArcCurve.type should be ArcCurve'
                        );
                    });

                    // PUBLIC
                    QUnit.test('isArcCurve', (assert) -> {
                        var object = new ArcCurve();
                        assert.ok(
                            object.isArcCurve,
                            'ArcCurve.isArcCurve should be true'
                        );
                    });
                });
            });
        });
    }
}