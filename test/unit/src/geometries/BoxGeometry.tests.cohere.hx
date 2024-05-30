import js.QUnit;

import js.threed.geometries.BoxGeometry;
import js.threed.core.BufferGeometry;
import js.threed.utils.qunit.qunit_utils.runStdGeometryTests;

class _Main {
    static function main() {
        var geometries:Array<BoxGeometry>;

        var parameters = {
            width: 10,
            height: 20,
            depth: 30,
            widthSegments: 2,
            heightSegments: 3,
            depthSegments: 4
        };

        QUnit.module('Geometries', function () {
            QUnit.module('BoxGeometry', function (hooks) {
                hooks.beforeEach(function () {
                    geometries = [
                        new BoxGeometry(),
                        new BoxGeometry(parameters.width, parameters.height, parameters.depth),
                        new BoxGeometry(parameters.width, parameters.height, parameters.depth, parameters.widthSegments, parameters.heightSegments, parameters.depthSegments)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new BoxGeometry();
                    assert.strictEqual(object instanceof BufferGeometry, true, 'BoxGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new BoxGeometry();
                    assert.ok(object, 'Can instantiate a BoxGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new BoxGeometry();
                    assert.ok(object.type == 'BoxGeometry', 'BoxGeometry.type should be BoxGeometry');
                });

                QUnit.todo('parameters', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo('fromJSON', function (assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test('Standard geometry tests', function (assert) {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}