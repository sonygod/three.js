package three.js.test.unit.src.extras.core;

import three.js.src.extras.core.Path;
import three.js.src.extras.core.CurvePath;
import js.QUnit;

class PathTests {
    public static function main() {
        QUnit.module('Extras', () -> {
            QUnit.module('Core', () -> {
                QUnit.module('Path', () -> {
                    // INHERITANCE
                    QUnit.test('Extending', (assert) -> {
                        var object = new Path();
                        assert.strictEqual(
                            Std.is(object, CurvePath), true,
                            'Path extends from CurvePath'
                        );
                    });

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {
                        var object = new Path();
                        assert.ok(object, 'Can instantiate a Path.');
                    });

                    // PROPERTIES
                    QUnit.test('type', (assert) -> {
                        var object = new Path();
                        assert.ok(
                            object.type == 'Path',
                            'Path.type should be Path'
                        );
                    });

                    QUnit.todo('currentPoint', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    // PUBLIC
                    QUnit.todo('setFromPoints', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('moveTo', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('lineTo', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('quadraticCurveTo', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('bezierCurveTo', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('splineThru', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('arc', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('absarc', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('ellipse', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('absellipse', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('copy', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('toJSON', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('fromJSON', (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}