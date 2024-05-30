package three.test.unit.src.geometries;

import haxe.unit.TestCase;
import three.geometries.IcosahedronGeometry;
import three.geometries.PolyhedronGeometry;
import three.test.unit.utils.QUnitUtils;

class IcosahedronGeometryTests {
    public function new() {}

    public static function main() {
        var testCase = new IcosahedronGeometryTests();
        testCase.test();
    }

    public function test() {
        var geometries:Array<IcosahedronGeometry>;

        beforeEach(function() {
            var parameters = {
                radius: 10,
                detail: null
            };
            geometries = [
                new IcosahedronGeometry(),
                new IcosahedronGeometry(parameters.radius),
                new IcosahedronGeometry(parameters.radius, parameters.detail),
            ];
        });

        // INHERITANCE
        test('Extending', function(assert) {
            var object = new IcosahedronGeometry();
            assert.isTrue(object instanceof PolyhedronGeometry, 'IcosahedronGeometry extends from PolyhedronGeometry');
        });

        // INSTANCING
        test('Instancing', function(assert) {
            var object = new IcosahedronGeometry();
            assert.notNull(object, 'Can instantiate an IcosahedronGeometry.');
        });

        // PROPERTIES
        test('type', function(assert) {
            var object = new IcosahedronGeometry();
            assert.equal(object.type, 'IcosahedronGeometry', 'IcosahedronGeometry.type should be IcosahedronGeometry');
        });

        // todo: implement parameters test
        test('parameters', function(assert) {
            assert.fail('todo: implement parameters test');
        });

        // todo: implement fromJSON test
        test('fromJSON', function(assert) {
            assert.fail('todo: implement fromJSON test');
        });

        // OTHERS
        test('Standard geometry tests', function(assert) {
            QUnitUtils.runStdGeometryTests(assert, geometries);
        });
    }
}