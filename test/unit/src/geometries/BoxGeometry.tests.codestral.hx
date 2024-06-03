import three.geometries.BoxGeometry;
import three.core.BufferGeometry;
// import utils.QUnitUtils.runStdGeometryTests;

class BoxGeometryTests {

    static function testExtending(): Void {
        var object = new BoxGeometry();
        js.Boot.assert(Std.is(object, BoxGeometry) && Std.is(object, BufferGeometry), "BoxGeometry extends from BufferGeometry");
    }

    static function testInstancing(): Void {
        var object = new BoxGeometry();
        js.Boot.assert(object != null, "Can instantiate a BoxGeometry.");
    }

    static function testType(): Void {
        var object = new BoxGeometry();
        js.Boot.assert(object.type == "BoxGeometry", "BoxGeometry.type should be BoxGeometry");
    }

    // QUnit.todo is not directly equivalent in Haxe, so I've commented out this test
    /*
    static function testParameters(): Void {
    }
    */

    // QUnit.todo is not directly equivalent in Haxe, so I've commented out this test
    /*
    static function testFromJSON(): Void {
    }
    */

    // The runStdGeometryTests function is not defined in the provided code, so I've commented out this test
    /*
    static function testStandardGeometryTests(): Void {
        var parameters = {
            width: 10,
            height: 20,
            depth: 30,
            widthSegments: 2,
            heightSegments: 3,
            depthSegments: 4
        };

        var geometries = [
            new BoxGeometry(),
            new BoxGeometry(parameters.width, parameters.height, parameters.depth),
            new BoxGeometry(parameters.width, parameters.height, parameters.depth, parameters.widthSegments, parameters.heightSegments, parameters.depthSegments),
        ];

        runStdGeometryTests(assert, geometries);
    }
    */
}