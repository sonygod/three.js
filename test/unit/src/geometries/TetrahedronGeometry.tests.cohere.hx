import js.QUnit;
import js.geom.TetrahedronGeometry;
import js.geom.PolyhedronGeometry;
import js.geom.qunit.utils.runStdGeometryTests;

class _TetrahedronGeometryTest {
    static function extend() {
        var object = new TetrahedronGeometry();
        QUnit.strictEqual(Std.is(object, PolyhedronGeometry), true, 'TetrahedronGeometry extends from PolyhedronGeometry');
    }

    static function instantiate() {
        var object = new TetrahedronGeometry();
        QUnit.ok(object, 'Can instantiate a TetrahedronGeometry.');
    }

    static function type() {
        var object = new TetrahedronGeometry();
        QUnit.ok(object.type == 'TetrahedronGeometry', 'TetrahedronGeometry.type should be TetrahedronGeometry');
    }

    static function parameters() {
        // TODO: Implement parameters test
    }

    static function fromJSON() {
        // TODO: Implement fromJSON test
    }

    static function standardGeometryTests() {
        var parameters = { radius: 10, detail: null };
        var geometries = [
            new TetrahedronGeometry(),
            new TetrahedronGeometry(parameters.radius),
            new TetrahedronGeometry(parameters.radius, parameters.detail)
        ];

        runStdGeometryTests(geometries);
    }
}

QUnit.module('Geometries', {
    beforeEach: function() {
        // No setup needed
    }
});

QUnit.module('TetrahedronGeometry', {
    beforeEach: function() {
        // No setup needed
    }
});

QUnit.test('Extending', _TetrahedronGeometryTest.extend);
QUnit.test('Instancing', _TetrahedronGeometryTest.instantiate);
QUnit.test('type', _TetrahedronGeometryTest.type);
QUnit.test('parameters', _TetrahedronGeometryTest.parameters);
QUnit.test('fromJSON', _TetrahedronGeometryTest.fromJSON);
QUnit.test('Standard geometry tests', _TetrahedronGeometryTest.standardGeometryTests);