package three.geom;

import haxe.unit.TestCase;
import three.geom.TorusGeometry;
import three.core.BufferGeometry;
import three.utils.QUnitUtils;

class TorusGeometryTest extends TestCase {

    private var geometries:Array<TorusGeometry>;

    override public function setUp():Void {
        var parameters = {
            radius: 10,
            tube: 20,
            radialSegments: 30,
            tubularSegments: 10,
            arc: 2.0
        };

        geometries = [
            new TorusGeometry(),
            new TorusGeometry(parameters.radius),
            new TorusGeometry(parameters.radius, parameters.tube),
            new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments),
            new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments),
            new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments, parameters.arc)
        ];
    }

    public function testExtending():Void {
        var object = new TorusGeometry();
        assertTrue(object instanceof BufferGeometry, 'TorusGeometry extends from BufferGeometry');
    }

    public function testInstancing():Void {
        var object = new TorusGeometry();
        assertNotNull(object, 'Can instantiate a TorusGeometry.');
    }

    public function testType():Void {
        var object = new TorusGeometry();
        assertEquals(object.type, 'TorusGeometry', 'TorusGeometry.type should be TorusGeometry');
    }

    public function todoParameters():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFromJSON():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testStandardGeometryTests():Void {
        QUnitUtils.runStdGeometryTests(geometries);
    }

}