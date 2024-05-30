import js.QUnit;
import js.PlaneGeometry;
import js.BufferGeometry;
import js.runStdGeometryTests;

class _Main {
    static function main() {
        var geometries:Array<PlaneGeometry> = [];
        var parameters = { width: 10, height: 30, widthSegments: 3, heightSegments: 5 };

        QUnit.module('Geometries', function () {
            QUnit.module('PlaneGeometry', function (hooks) {
                hooks.beforeEach(function () {
                    geometries = [
                        new PlaneGeometry(),
                        new PlaneGeometry(parameters.width),
                        new PlaneGeometry(parameters.width, parameters.height),
                        new PlaneGeometry(parameters.width, parameters.height, parameters.widthSegments),
                        new PlaneGeometry(parameters.width, parameters.height, parameters.widthSegments, parameters.heightSegments)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function (assert) {
                    var object = new PlaneGeometry();
                    assert.strictEqual(object instanceof BufferGeometry, true, 'PlaneGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function (assert) {
                    var object = new PlaneGeometry();
                    assert.ok(object, 'Can instantiate a PlaneGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function (assert) {
                    var object = new PlaneGeometry();
                    assert.ok(object.type == 'PlaneGeometry', 'PlaneGeometry.type should be PlaneGeometry');
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