package geometries;

import js.QUnit;
import js.Array;

import geometries.CapsuleGeometry;
import geometries.LatheGeometry;
import utils.qunit.qunit_utils.runStdGeometryTests;

class CapsuleGeometryTest {
    static function test() {
        var geometries = [];
        var parameters = {
            radius: 2,
            length: 2,
            capSegments: 20,
            radialSegments: 20
        };

        geometries.push(new CapsuleGeometry());
        geometries.push(new CapsuleGeometry(parameters.radius));
        geometries.push(new CapsuleGeometry(parameters.radius, parameters.length));
        geometries.push(new CapsuleGeometry(parameters.radius, parameters.length, parameters.capSegments));
        geometries.push(new CapsuleGeometry(parameters.radius, parameters.length, parameters.capSegments, parameters.radialSegments));

        QUnit.module('Geometries');

        QUnit.module('CapsuleGeometry', function(hooks) {
            hooks.beforeEach(function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new CapsuleGeometry();
                    assert.strictEqual(object instanceof LatheGeometry, true, 'CapsuleGeometry extends from LatheGeometry');
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new CapsuleGeometry();
                    assert.ok(object, 'Can instantiate a CapsuleGeometry.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new CapsuleGeometry();
                    assert.ok(object.type == 'CapsuleGeometry', 'CapsuleGeometry.type should be CapsuleGeometry');
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

CapsuleGeometryTest.test();