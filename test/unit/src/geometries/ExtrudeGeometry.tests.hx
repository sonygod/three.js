package three.geom.test;

import haxe.unit.TestCase;
import three.geom.ExtrudeGeometry;
import three.core.BufferGeometry;

class ExtrudeGeometryTest {
    public function new() {}

    public function testExtending() {
        var object = new ExtrudeGeometry();
        assertTrue(object instanceof BufferGeometry, 'ExtrudeGeometry extends from BufferGeometry');
    }

    public function testInstancing() {
        var object = new ExtrudeGeometry();
        assertNotNull(object, 'Can instantiate an ExtrudeGeometry.');
    }

    public function testType() {
        var object = new ExtrudeGeometry();
        assertEquals(object.type, 'ExtrudeGeometry', 'ExtrudeGeometry.type should be ExtrudeGeometry');
    }

    public function testParameters() {
        // TODO: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testToJSON() {
        // TODO: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testFromJSON() {
        // TODO: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }
}