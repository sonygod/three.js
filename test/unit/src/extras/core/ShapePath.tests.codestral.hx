import js.Browser.document;
import js.html.QUnit;
import three.extras.core.ShapePath;

class ShapePathTests {
    public function new() {
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
                        assert.ok(
                            object.type == 'ShapePath',
                            'ShapePath.type should be ShapePath'
                        );
                    });

                    // TODO: Implement the remaining tests

                    // QUnit.todo('color', (assert) -> {
                    //     // ...
                    // });

                    // QUnit.todo('subPaths', (assert) -> {
                    //     // ...
                    // });

                    // QUnit.todo('currentPath', (assert) -> {
                    //     // ...
                    // });

                    // PUBLIC
                    // QUnit.todo('moveTo', (assert) -> {
                    //     // ...
                    // });

                    // QUnit.todo('lineTo', (assert) -> {
                    //     // ...
                    // });

                    // QUnit.todo('quadraticCurveTo', (assert) -> {
                    //     // ...
                    // });

                    // QUnit.todo('bezierCurveTo', (assert) -> {
                    //     // ...
                    // });

                    // QUnit.todo('splineThru', (assert) -> {
                    //     // ...
                    // });

                    // QUnit.todo('toShapes', (assert) -> {
                    //     // ...
                    // });

                });
            });
        });
    }
}