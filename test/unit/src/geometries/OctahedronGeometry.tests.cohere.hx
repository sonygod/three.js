import js.QUnit;
import js.OctahedronGeometry;
import js.PolyhedronGeometry;
import js.runStdGeometryTests;

class _Main {
    static function main() {
        var geometries = [];
        var parameters = { radius: 10, detail: null };

        function beforeEach() {
            geometries = [
                new js.OctahedronGeometry(),
                new js.OctahedronGeometry(parameters.radius),
                new js.OctahedronGeometry(parameters.radius, parameters.detail)
            ];
        }

        QUnit.module('Geometries', function (hooks) {
            hooks.beforeEach(beforeEach);

            QUnit.module('OctahedronGeometry', function () {
                QUnit.test('Extending', function (assert) {
                    var object = new js.OctahedronGeometry();
                    assert.strictEqual(
                        object instanceof js.PolyhedronGeometry, true,
                        'OctahedronGeometry extends from PolyhedronGeometry'
                    );
                });

                QUnit.test('Instancing', function (assert) {
                    var object = new js.OctahedronGeometry();
                    assert.ok(object, 'Can instantiate an OctahedronGeometry.');
                });

                QUnit.test('type', function (assert) {
                    var object = new js.OctahedronGeometry();
                    assert.ok(
                        object.type == 'OctahedronGeometry',
                        'OctahedronGeometry.type should be OctahedronGeometry'
                    );
                });

                QUnit.test('Standard geometry tests', function (assert) {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}