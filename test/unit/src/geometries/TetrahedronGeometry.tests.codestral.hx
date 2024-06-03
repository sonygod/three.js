package test.unit.geometries;

import threejs.src.geometries.TetrahedronGeometry;
import threejs.src.geometries.PolyhedronGeometry;
// import utils.qunit_utils.runStdGeometryTests; // Uncomment this line when you have a Haxe equivalent for this function

class TetrahedronGeometryTests {
    static function main() {
        // INSTANCING
        var object:TetrahedronGeometry = new TetrahedronGeometry();
        trace("Can instantiate a TetrahedronGeometry: ${object != null}");

        // PROPERTIES
        trace("TetrahedronGeometry.type should be TetrahedronGeometry: ${object.type == 'TetrahedronGeometry'}");

        // INHERITANCE
        trace("TetrahedronGeometry extends from PolyhedronGeometry: ${object is PolyhedronGeometry}");

        // OTHERS
        // Uncomment this line when you have a Haxe equivalent for this function
        // runStdGeometryTests(assert, geometries);
    }
}