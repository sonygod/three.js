package three.geom;

import three.geom.ExtrudeGeometry;
import three.core.BufferGeometry;

class Geometries {

    public function new() {}

    public static function main() {
        haxe.unit.TestSuite.addTestCase(new Geometries());
    }

    public function testExtrudeGeometry() {
        // INHERITANCE
        var object = new ExtrudeGeometry();
        assertTrue(object instanceof BufferGeometry, 'ExtrudeGeometry extends from BufferGeometry');

        // INSTANCING
        object = new ExtrudeGeometry();
        assertTrue(object != null, 'Can instantiate an ExtrudeGeometry.');

        // PROPERTIES
        object = new ExtrudeGeometry();
        assertEquals(object.type, 'ExtrudeGeometry', 'ExtrudeGeometry.type should be ExtrudeGeometry');

        // TODO: implement parameters test
        // TODO: implement toJSON test
        // TODO: implement fromJSON test
    }
}