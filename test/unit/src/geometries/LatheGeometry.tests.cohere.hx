import js.QUnit;
import js.ArrayBufferGeometry.LatheGeometry;
import js.ArrayBufferGeometry.BufferGeometry;
import js.ArrayBufferGeometry.qunit_utils.runStdGeometryTests;

class _Main {
    static function main() {
        var geometries:Array<LatheGeometry>;

        var hooks = { beforeEach: function() {
            var parameters = {
                points: [],
                segments: 0,
                phiStart: 0,
                phiLength: 0
            };

            geometries = [
                new LatheGeometry(parameters.points)
            ];
        }};

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new LatheGeometry();
            assert.strictEqual(object instanceof BufferGeometry, true, 'LatheGeometry extends from BufferGeometry');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new LatheGeometry();
            assert.ok(object, 'Can instantiate a LatheGeometry.');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
            var object = new LatheGeometry();
            assert.ok(object.type == 'LatheGeometry', 'LatheGeometry.type should be LatheGeometry');
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
    }
}