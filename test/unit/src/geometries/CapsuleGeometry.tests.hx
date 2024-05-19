package three.geom;

import haxe.unit.TestCase;
import three.geom.CapsuleGeometry;
import three.geom.LatheGeometry;
import three.utils.QUnitUtils;

class CapsuleGeometryTests {

    public function new() {}

    public static function main() {
        TestCase.createTestSuite(CapsuleGeometryTests);
    }

    public function testInheritance() {
        var object:CapsuleGeometry = new CapsuleGeometry();
        assertEquals(object instanceof LatheGeometry, true, 'CapsuleGeometry extends from LatheGeometry');
    }

    public function testInstancing() {
        var object:CapsuleGeometry = new CapsuleGeometry();
        assertNotNull(object, 'Can instantiate a CapsuleGeometry.');
    }

    public function testType() {
        var object:CapsuleGeometry = new CapsuleGeometry();
        assertEquals(object.type, 'CapsuleGeometry', 'CapsuleGeometry.type should be CapsuleGeometry');
    }

    public function testTodoParameters() {
        TODO('everything\'s gonna be alright');
    }

    public function testTodoFromJSON() {
        TODO('everything\'s gonna be alright');
    }

    public function testStandardGeometryTests() {
        var geometries:Array<CapsuleGeometry> = [];
        geometries.push(new CapsuleGeometry());
        geometries.push(new CapsuleGeometry(2));
        geometries.push(new CapsuleGeometry(2, 2));
        geometries.push(new CapsuleGeometry(2, 2, 20));
        geometries.push(new CapsuleGeometry(2, 2, 20, 20));
        QUnitUtils.runStdGeometryTests(geometries);
    }
}