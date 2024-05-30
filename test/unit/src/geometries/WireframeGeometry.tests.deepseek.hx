package three.js.test.unit.src.geometries;

import three.js.src.core.BufferGeometry;
import three.js.src.geometries.WireframeGeometry;

class WireframeGeometryTest {

    public static function main() {
        var geometries:Array<WireframeGeometry>;

        // Extending
        var object = new WireframeGeometry();
        unittest.Assert.isTrue(Std.is(object, BufferGeometry), 'WireframeGeometry extends from BufferGeometry');

        // Instancing
        var object = new WireframeGeometry();
        unittest.Assert.isNotNull(object, 'Can instantiate a WireframeGeometry.');

        // Properties
        var object = new WireframeGeometry();
        unittest.Assert.isTrue(object.type == 'WireframeGeometry', 'WireframeGeometry.type should be WireframeGeometry');

        // TODO: parameters
        unittest.Assert.isTrue(false, 'everything\'s gonna be alright');

        // TODO: Standard geometry tests
        unittest.Assert.isTrue(false, 'everything\'s gonna be alright');
    }
}