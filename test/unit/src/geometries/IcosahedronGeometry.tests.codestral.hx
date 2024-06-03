import three.geometries.IcosahedronGeometry;
import three.geometries.PolyhedronGeometry;
import unittest.TestCase;

class IcosahedronGeometryTests extends TestCase {
    var geometries: Array<IcosahedronGeometry>;

    override function setUp() {
        var parameters = { radius: 10, detail: null };

        geometries = [
            new IcosahedronGeometry(),
            new IcosahedronGeometry(parameters.radius),
            new IcosahedronGeometry(parameters.radius, parameters.detail)
        ];
    }

    @Test public function testExtending() {
        var object = new IcosahedronGeometry();
        assertTrue(Std.is(object, PolyhedronGeometry), "IcosahedronGeometry extends from PolyhedronGeometry");
    }

    @Test public function testInstancing() {
        var object = new IcosahedronGeometry();
        assertNotNull(object, "Can instantiate an IcosahedronGeometry.");
    }

    @Test public function testType() {
        var object = new IcosahedronGeometry();
        assertEquals("IcosahedronGeometry", object.type, "IcosahedronGeometry.type should be IcosahedronGeometry");
    }

    // TODO: Implement 'parameters' test

    // TODO: Implement 'fromJSON' test

    // TODO: Implement 'Standard geometry tests'
}