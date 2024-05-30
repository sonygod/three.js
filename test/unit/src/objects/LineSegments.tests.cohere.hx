import js.QUnit;
import js.Object3D;
import js.Line;
import js.LineSegments;

class TestLineSegments {
    static function main() {
        QUnit.module('Objects', {
            setup: function() {},
            teardown: function() {}
        });

        QUnit.module('LineSegments', {
            setup: function() {},
            teardown: function() {}
        });

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var lineSegments = new LineSegments();
            assert.strictEqual(lineSegments instanceof Object3D, true, 'LineSegments extends from Object3D');
            assert.strictEqual(lineSegments instanceof Line, true, 'LineSegments extends from Line');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new LineSegments();
            assert.ok(object, 'Can instantiate a LineSegments.');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
            var object = new LineSegments();
            assert.strictEqual(object.type, 'LineSegments', 'LineSegments.type should be LineSegments');
        });

        // PUBLIC
        QUnit.test('isLineSegments', function(assert) {
            var object = new LineSegments();
            assert.strictEqual(object.isLineSegments, true, 'LineSegments.isLineSegments should be true');
        });

        QUnit.todo('computeLineDistances', function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}