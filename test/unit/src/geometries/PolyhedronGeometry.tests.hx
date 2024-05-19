package three.js.test.unit.src.geometries;

import haxe.unit.TestCase;
import three.js.geometries.PolyhedronGeometry;
import three.js.core.BufferGeometry;
import three.js.test.unit.utils.QUnitUtils;

class PolyhedronGeometryTests extends TestCase {

    var geometries:Array<PolyhedronGeometry>;

    override public function setup() {
        var vertices:Array<Float> = [
            1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1
        ];

        var indices:Array<Int> = [
            2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1
        ];

        geometries = [
            new PolyhedronGeometry(vertices, indices)
        ];
    }

    public function testExtending() {
        var object = new PolyhedronGeometry();
        assertTrue(object instanceof BufferGeometry, 'PolyhedronGeometry extends from BufferGeometry');
    }

    public function testInstancing() {
        var object = new PolyhedronGeometry();
        assertTrue(object != null, 'Can instantiate a PolyhedronGeometry.');
    }

    public function testType() {
        var object = new PolyhedronGeometry();
        assertEquals(object.type, 'PolyhedronGeometry', 'PolyhedronGeometry.type should be PolyhedronGeometry');
    }

    public function todoParameters() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFromJSON() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testStandardGeometryTests() {
        QUnitUtils.runStdGeometryTests(geometries);
    }
}