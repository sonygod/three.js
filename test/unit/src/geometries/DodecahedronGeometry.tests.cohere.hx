package;

import js.QUnit;
import js.dodge.src.geometries.DodecahedronGeometry;
import js.dodge.src.geometries.PolyhedronGeometry;
import js.dodge.utils.qunit.runStdGeometryTests;

class _DodecahedronGeometryTest {
    static function qunit() {
        var geometries : Array<DodecahedronGeometry>;

        var parameters = {
            radius : 10,
            detail : null
        };

        QUnit.module('Geometries', function() {
            QUnit.module('DodecahedronGeometry', function(hooks) {
                hooks.beforeEach(function() {
                    geometries = [
                        new DodecahedronGeometry(),
                        new DodecahedronGeometry(parameters.radius),
                        new DodecahedronGeometry(parameters.radius, parameters.detail)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new DodecahedronGeometry();
                    assert.strictEqual(object instanceof PolyhedronGeometry, true, 'DodecahedronGeometry extends from PolyhedronGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new DodecahedronGeometry();
                    assert.ok(object, 'Can instantiate a DodecahedronGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new DodecahedronGeometry();
                    assert.ok(object.type == 'DodecahedronGeometry', 'DodecahedronGeometry.type should be DodecahedronGeometry');
                });

                QUnit.todo('parameters', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo('fromJSON', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test('Standard geometry tests', function(assert) {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}

_DodecahedronGeometryTest.qunit();