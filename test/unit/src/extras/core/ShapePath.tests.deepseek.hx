package three.js.test.unit.src.extras.core;

import three.js.src.extras.core.ShapePath;
import js.Lib.QUnit;

class ShapePathTests {

    public static function main() {

        QUnit.module('Extras', () -> {

            QUnit.module('Core', () -> {

                QUnit.module('ShapePath', () -> {

                    // INSTANCING
                    QUnit.test('Instancing', (assert) -> {

                        var object = new ShapePath();
                        assert.ok(object != null, 'Can instantiate a ShapePath.');

                    });

                    // PROPERTIES
                    QUnit.test('type', (assert) -> {

                        var object = new ShapePath();
                        assert.ok(object.type == 'ShapePath', 'ShapePath.type should be ShapePath');

                    });

                    QUnit.todo('color', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('subPaths', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    QUnit.todo('currentPath', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                    // PUBLIC
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

                    QUnit.todo('toShapes', (assert) -> {

                        assert.ok(false, 'everything\'s gonna be alright');

                    });

                });

            });

        });

    }

}